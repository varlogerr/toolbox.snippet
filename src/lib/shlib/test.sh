shlib_test() {
  declare -p SHLIB_TEST_STATS 2>/dev/null | grep -q '^declare\s\+-A' || {
    unset SHLIB_TEST_STATS
    declare -gA SHLIB_TEST_STATS
  }
  grep -qx '[0-9]\+' <<< "${SHLIB_TEST_STATS[OK]}" || SHLIB_TEST_STATS[OK]=0
  grep -qx '[0-9]\+' <<< "${SHLIB_TEST_STATS[KO]}" || SHLIB_TEST_STATS[KO]=0
  grep -qx '[0-9]\+' <<< "${SHLIB_TEST_STATS[SKIP]}" || SHLIB_TEST_STATS[SKIP]=0

  # [current] [title] [stdout] [stderr] [rc] [cmd_name] [workdir]
  declare -A OPTS_f1GlLuNQHx=(
    [noout]=false
    [noerr]=false
    [norc]=false
    [skip]=false
    [endopts]=false
    [rc]=0
  )
  declare -a BEFORE_f1GlLuNQHx
  declare -a AFTER_f1GlLuNQHx
  # [outfile] [errfile] [stdout] [stderr] [rc]
  declare -A RESULT_f1GlLuNQHx
  # Command to run
  declare -a CMD_f1GlLuNQHx ERRBAG

  while [[ -n "${1+x}" ]]; do
    ${OPTS_f1GlLuNQHx[endopts]} && OPTS_f1GlLuNQHx[current]='*' || OPTS_f1GlLuNQHx[current]="${1}"

    case "${OPTS_f1GlLuNQHx[current]}" in
      --                ) OPTS_f1GlLuNQHx[endopts]=true ;;
      -t|--title        ) OPTS_f1GlLuNQHx[title]="${2}"; shift ;;
      -b|--before       ) BEFORE_f1GlLuNQHx+=("${2}"); shift ;;
      -a|--after        ) AFTER_f1GlLuNQHx+=("${2}"); shift ;;
      -o|--out|--stdout ) OPTS_f1GlLuNQHx[stdout]+="${OPTS_f1GlLuNQHx[stdout]+${SHLIB_NL}}${2}"; shift ;;
      -e|--err|--stderr ) OPTS_f1GlLuNQHx[stderr]+="${OPTS_f1GlLuNQHx[stderr]+${SHLIB_NL}}${2}"; shift ;;
      -c|--rc           ) OPTS_f1GlLuNQHx[rc]="${2}"; shift ;;
      -O|--noout        ) OPTS_f1GlLuNQHx[noout]=true ;;
      -E|--noerr        ) OPTS_f1GlLuNQHx[noerr]=true ;;
      -C|--norc         ) OPTS_f1GlLuNQHx[norc]=true ;;
      --skip            ) OPTS_f1GlLuNQHx[skip]=true ;;
      * ) OPTS_f1GlLuNQHx[endopts]=true
        CMD_f1GlLuNQHx+=("${1}")
        ;;
    esac

    shift
  done

  [[
    -n "${SHLIB_TEST_EXACT}" \
    && "${CMD_f1GlLuNQHx[0]}" != "${SHLIB_TEST_EXACT}"
  ]] && return

  # Initially increment it in case something fails. Decrement
  # in the end if it's OK
  (( SHLIB_TEST_STATS[KO]++ ))

  { # Validation
    grep -qx '[0-9]\+' <<< "${OPTS_f1GlLuNQHx[rc]}" || ERRBAG+=("Invalid RC value: '${OPTS_f1GlLuNQHx[rc]}'.")
    [[ ${#CMD_f1GlLuNQHx[@]} -gt 0 ]] || ERRBAG+=("CMD is required.")

    { # Validate hook
      declare -a hooks=("${BEFORE_f1GlLuNQHx[@]}" "${AFTER_f1GlLuNQHx[@]}")
      declare h; for h in "${hooks[@]}"; do
        declare -F "${h}" &>/dev/null || ERRBAG+=(
          "Hook function can't be found: '${h}'."
        )
      done
      unset -v hooks h
    } # Validate hook

    OPTS_f1GlLuNQHx[cmd_name]="${CMD_f1GlLuNQHx[0]}"

    declare -a tmp_cmd; tmp_cmd=("${OPTS_f1GlLuNQHx[cmd_name]}")
    declare -a tmp_lines; tmp_lines=("$(
      command -pv "${tmp_cmd[@]}" 2>/dev/null
    )") && [[ ${#tmp_lines[@]} -eq ${#tmp_cmd[@]} ]] || ERRBAG+=(
      "CMD can't be found: '${OPTS_f1GlLuNQHx[cmd_name]}'."
    )
    unset -v tmp_lines tmp_cmd

    [[ ${#ERRBAG[@]} -lt 1 ]] || {
      printf -- '%s\n' "${ERRBAG[@]}" | log_fuck
      return 2
    }

    unset -v ERRBAG
  } # Validation

  # Fix the command
  [[ "${CMD_f1GlLuNQHx[0]}" == *' '* ]] && {
    declare -a tmp_cmd
    # shellcheck disable=SC2206
    tmp_cmd=(${CMD_f1GlLuNQHx[0]})
    unset 'CMD_f1GlLuNQHx[0]'
    CMD_f1GlLuNQHx=("${tmp_cmd[@]}" "${CMD_f1GlLuNQHx[@]}")

    unset tmp_cmd
  }

  ${OPTS_f1GlLuNQHx[skip]} && {
    declare prefix; prefix="$(
      printf -- '[test:%s:%s] ' "${OPTS_f1GlLuNQHx[cmd_name]}" SKIP
    )"
    text_prefix "${prefix}" <<< "${OPTS_f1GlLuNQHx[title]}"

    (( SHLIB_TEST_STATS[KO]-- ))
    (( SHLIB_TEST_STATS[SKIP]++ ))

    return
  }

  # Create working space
  OPTS_f1GlLuNQHx[workdir]="$(mktemp -d --suffix .test.shlib 2>/dev/null || mktemp)" || {
    log_fuck <<< "Can't create workdir."
    return 2
  }
  RESULT_f1GlLuNQHx[outfile]="${OPTS_f1GlLuNQHx[workdir]}/out.txt"
  RESULT_f1GlLuNQHx[errfile]="${OPTS_f1GlLuNQHx[workdir]}/err.txt"
  truncate -s 0 -- "${RESULT_f1GlLuNQHx[outfile]}" "${RESULT_f1GlLuNQHx[errfile]}" 2>/dev/null || {
    _shlib_test_cleanup
    printf -- "Can't create stream file: %s\n" \
      "${RESULT_f1GlLuNQHx[outfile]}" \
      "${RESULT_f1GlLuNQHx[errfile]}" | log_fuck

    return 2
  }

  ( # Execute tested functions and trap the result
    declare -F shlib_test_setup &>/dev/null && shlib_test_setup

    declare hook_f1GlLuNQHx; for hook_f1GlLuNQHx in "${BEFORE_f1GlLuNQHx[@]}"; do
      "${hook_f1GlLuNQHx}"
    done; unset -v hook_f1GlLuNQHx

    "${CMD_f1GlLuNQHx[@]}" >"${RESULT_f1GlLuNQHx[outfile]}" 2>"${RESULT_f1GlLuNQHx[errfile]}"
    RESULT_f1GlLuNQHx[rc]=$?

    declare hook_f1GlLuNQHx; for hook_f1GlLuNQHx in "${AFTER_f1GlLuNQHx[@]}"; do
      "${hook_f1GlLuNQHx}"
    done

    declare -F shlib_test_teardown &>/dev/null && shlib_test_teardown

    shlib_test_rc
  ); shlib_test_rc $? # Execute tested functions and trap the result

  declare TEST_RESULT=OK
  declare -a ERRBAG

  shlib_test_rc; declare rc=$?
  # shellcheck disable=SC2031
  [[ ${rc} -eq ${OPTS_f1GlLuNQHx[rc]} ]] || {
    ERRBAG+=("$(
      text_prefix '  ' <<< "< ${OPTS_f1GlLuNQHx[rc]}${SHLIB_NL}> ${rc}" \
      | text_wrap '```RC ("< expected" VS "> actual")' '```'
    )")
  }

  declare diff
  declare stream; for stream in stdout stderr; do
    diff="$(_shlib_test_stream_diff "${stream}")" && {
      ERRBAG+=("$(
        text_prefix '  ' <<< "${diff}" | text_wrap \
          '```'"${stream^^}"' ("< expected" VS "> actual")' '```'
      )")
    }
  done

  [[ ${#ERRBAG[@]} -gt 0 ]] && {
    TEST_RESULT=KO
    ERRBAG+=("$(
      declare i; for i in "${CMD_f1GlLuNQHx[@]}"; do
        printf '"%s" ' "$(escape_quote_double <<< "${i}")"
      done | sed 's/ $//' | text_prefix '  ' | text_wrap '```CMD' '```'
    )")

    [[ ${#BEFORE_f1GlLuNQHx[@]} -gt 0 ]] && ERRBAG+=("$(
      declare -f "${BEFORE_f1GlLuNQHx[@]}" | text_prefix '  ' \
      | text_wrap '```BEFORE' '```'
    )")

    [[ ${#AFTER_f1GlLuNQHx[@]} -gt 0 ]] && ERRBAG+=("$(
      declare -f "${AFTER_f1GlLuNQHx[@]}" | text_prefix '  ' \
      | text_wrap '```AFTER' '```'
    )")
  }

  declare prefix; prefix="$(
    printf -- '[test:%s:%s] ' "${OPTS_f1GlLuNQHx[cmd_name]}" "${TEST_RESULT}"
  )"
  text_prefix "${prefix}" <<< "${OPTS_f1GlLuNQHx[title]}"
  [[ ${#ERRBAG[@]} -gt 0 ]] && printf -- '%s\n' "${ERRBAG[@]}"

  (( SHLIB_TEST_STATS[KO]-- ))
  (( SHLIB_TEST_STATS["${TEST_RESULT}"]++ ))

  _shlib_test_cleanup
}

# shellcheck disable=SC2120
shlib_test_stdout() { _shlib_test_stream "${RESULT_f1GlLuNQHx[outfile]}" "${@}"; }
shlib_test_stderr() { _shlib_test_stream "${RESULT_f1GlLuNQHx[errfile]}" "${@}"; }
shlib_test_rc() {
  if [[ -n "${1+x}" ]]; then
    grep -qx '[0-9]\+' <<< "${1}" || {
      log_fatal "Invalid RC value: '${RESULT_f1GlLuNQHx[rc]}'."
      return 2
    }

    RESULT_f1GlLuNQHx[rc]=$1
  fi

  # shellcheck disable=SC2031
  return "${RESULT_f1GlLuNQHx[rc]}"
}

_shlib_test_stream() {
  declare file="${1}"

  [[ -n "${2+x}" ]] && { printf -- '%s' "${2}" > "${file}"; return 0; }
  grep '' "${file}" 2>/dev/null
}

# shellcheck disable=SC2120
_shlib_test_stream_diff() {
  declare stream="${1}"
  declare -A nocheck_map=(
    [stdout]=noout
    [stderr]=noerr
  )

  declare expected
  [[ -n "${OPTS_f1GlLuNQHx[${stream}]+x}" ]] && expected="${OPTS_f1GlLuNQHx[${stream}]}"

  # Check is not required for `--nocheck`:
  # shellcheck disable=SC2031
  ${OPTS_f1GlLuNQHx[${nocheck_map[${stream}]}]} && return 1

  declare actual
  declare tmp_actual; tmp_actual="$("shlib_test_${stream}")" && {
    actual="${tmp_actual}"
  } || {
    # No expected and actual, have no work here
    [[ -z "${expected+x}" ]] && return 1
  }

  diff <(printf -- '%s' "${expected}${expected+$'\n'}") \
    <(printf -- '%s' "${actual}${actual+$'\n'}") &>/dev/null \
  && return 1

  [[ -n "${expected+x}" ]] && {
    printf -- '%s' "${expected}${expected+$'\n'}" | sed 's/^/< /'
  }
  [[ -n "${actual+x}" ]] && {
    printf -- '%s' "${actual}${actual+$'\n'}" | sed 's/^/> /'
  }
  return 0
}

_shlib_test_cleanup() {
  [[ -n "${OPTS_f1GlLuNQHx[workdir]+x}" ]] && [[ -d "${OPTS_f1GlLuNQHx[workdir]}" ]] && {
    rm -rf "${OPTS_f1GlLuNQHx[workdir]}" 2>/dev/null
  }
}

shlib_test_gen_demo() {
  declare -r SELF="${BASH_SOURCE[0]}"
  declare SELF_BODY; SELF_BODY="$(cat -- "${SELF}")"
  declare -i lines; lines="$(wc -l <<< "${SELF_BODY}")"
  declare block_tag=SHLIB_TEMPLATE_TEST_DEMO_XLSn9loLhd

  grep -m1 -A"${lines}" '^\s*#\s*{{\s*'"${block_tag}"'\s*}}\s*$' \
    <<< "${SELF_BODY}" \
  | grep -m1 -B"${lines}" '^\s*#\s*{{\/\s*'"${block_tag}"'\s*}}\s*$' \
  | sed -e '1,2d' | head -n -2 | text_fmt
}

# {{ SHLIB_TEMPLATE_TEST_DEMO_XLSn9loLhd }}
  ( exit
    # TODO: update demo suite
    { # Test function
      demo_passthrough() {
        declare -a INPUTS=("${@}")
        [[ "${#INPUTS[@]}" -gt 0 ]] || {
          declare tmp; tmp="$(timeout 2 grep '')"
          declare RC=$?
          if [[ $RC -eq 0 ]]; then
            INPUTS+=("${tmp}")
          # grep no-match RC is 1, timeout RC is 124 or greater
          elif [[ $RC -gt 1 ]]; then
            echo "Input required." >&2
            return 2
          fi
        }

        if [[ ${#INPUTS[@]} -gt 0 ]]; then
          printf -- '%s\n' "${INPUTS[@]}"
        fi
      }
    } # Test function

    #
    # -t, --title           Test title
    # -b, --before          Before hook function
    # -a, --after           After hook function
    # -o, --out, --stdout   Expected stdout
    # -e, --err, --stderr   Expected stderr
    # -c, --rc              Expected RC
    # -O, --noout           Ignore stdout check
    # -E, --noerr           Ignore stderr check
    # -C, --norc            Ignore RC check
    #
    # shlib_test [-t|--title TEST_TITLE] \
    #   [-b|--before BEFORE_FUNC]... [-a|--after AFTER_FUNC]... \
    #   [-o|--out|--stdout EXP_STDOUT]... [-e|--err|--stderr EXP_STDERR]... \
    #   [-c|--rc EXP_RC] [-O|--noout]  [-E|--noerr] [-C|--norc] [--skip] \
    # CMD_TO_TEST [CMD_TO_TEST_OPTION]...

    { # Fixtures
      setup_mock_timeout() {
        # Mock to speed up timeout
        timeout() {
          unset "${FUNCNAME[0]}" # aka run once
          /usr/bin/env timeout 0.01 "${@:2}"
        }
      }

      _check_has_line() {
        (set -o pipefail
          shlib_test_stdout | grep -qFx "${1}"
        ); shlib_test_rc $?
      }

      check_has_line_baz() { _check_has_line 'baz'; }
    } # Fixtures

    #
    # TESTING
    #

    shlib_test_setup() {
      # Runs before each test, before 'BEFORE' hook
      :
    }
    shlib_test_teardown() {
      # Runs after each test, after 'AFTER' hook
      :
    }

    _test_demo_passthrough() {
      unset "${FUNCNAME[0]}"
      declare CMD=demo_passthrough

      # No stdout expected
      shlib_test --title 'Fails on no input' \
          --before setup_mock_timeout --err 'Input required.' -c 2 \
        "${CMD}"

      # No stdout expected, RC expected to be 0
      shlib_test --title 'Outputs single-line input arg' \
          --out 'Foo bar' \
        "${CMD}" "Foo bar"

      # 'Foo' and 'bar' expected on separate lines
      shlib_test --title 'Outputs multi-line input arg' \
          --out 'Foo' --out 'bar' \
        "${CMD}" "Foo${SHLIB_NL}bar"

      shlib_test --title 'Outputs multiple args' \
          --out "Foo${SHLIB_NL}bar${SHLIB_NL}baz" \
        "${CMD}" "Foo${SHLIB_NL}bar" "baz"

      shlib_test --title 'Output contains part of input' \
          --noout --after check_has_line_baz \
        "${CMD}" "Foo${SHLIB_NL}bar" "baz"

      shlib_test --title 'Reads from stdin' \
          --out "Foo${SHLIB_NL}bar" \
        "${CMD}" <<< "Foo${SHLIB_NL}bar"

      printf '' \
      | shlib_test -t "No output on empty stdin" \
        "${CMD}"
    }; _test_demo_passthrough
  )
# {{/ SHLIB_TEMPLATE_TEST_DEMO_XLSn9loLhd }}

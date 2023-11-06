#!/usr/bin/env bash

# Always here version placeholder
declare SNIP_VERSION='v20231106-d49623b' # {{ SNIP_VERSION /}}

declare SNIP_TEST_RUNNER_DIR; SNIP_TEST_RUNNER_DIR="$(dirname -- "${0}")"

# Ensure local development run
SNIP_LOCAL=true . "${SNIP_TEST_RUNNER_DIR}/snippet.sh"
# Ensure test lib is sourced
. "${SNIP_TEST_RUNNER_DIR}/src/lib/shlib/test.sh"

snip_test_collect_files() {
  declare -ag SNIP_TEST_FILES
  declare -a query=(-name '')
  [[ $# -gt 0 ]] && {
    while [[ -n "${1+x}" ]]; do
      query+=(-o -name "${1}.sh")
      shift
    done
  } || query=(-name '*.sh')

  declare bucket; bucket="$(
    find "${SNIP_TEST_RUNNER_DIR}/tests/suite" \
      -type f "${query[@]}" | sort -n
  )"; [[ -n "${bucket}" ]] && {
    mapfile -t SNIP_TEST_FILES <<< "${bucket}"
  }
}

snip_test_collect_init_fnames() {
  declare -ag SNIP_INIT_FNAMES

  declare bucket; bucket="$(
    declare -F | rev | cut -d' ' -f1 | rev
  )"; [[ -n "${bucket}" ]] && {
    mapfile -t SNIP_INIT_FNAMES <<< "${bucket}"
  }
}

snip_test_help() {
  declare SELF; SELF="$(basename -- "${0}" 2>/dev/null)"
  [[ -n "${SELF+x}" ]] || SELF="test.sh"

  text_fmt <(echo "
    Test snippet library.

    USAGE:
      ${SELF} [OPTION]...

      # Without SUITE provided runs them all
      ${SELF} [SUITE]...

    OPTS:
      -?, -h, --help  Print this help
      -l, --list      List available suites
      -v, --version   Print current version
  ")
}

# All before here can be sourced
(return 0 &>/dev/null) && return

################
#### ACTION ####
################

_iife_opts() {
  while [[ -n "${1}" ]]; do
    case "${1}" in
      -\?|-h|--help )
        snip_test_help
        exit
        ;;
      -v|--version )
        echo "${SNIP_VERSION}"
        exit
        ;;
      -l|--list )
        snip_test_collect_files
        printf -- '%s\n' "${SNIP_TEST_FILES[@]}" \
        | rev | cut -d'/' -f1 | rev | sed 's/\.sh$//'
        exit
        ;;
    esac

    shift
  done
}; _iife_opts "${@}"; unset _iife_opts

snip_test_collect_files "${@}"
snip_test_collect_init_fnames

shlib_test_setup() {
  # Unset all functions
  declare f; for f in "${SNIP_INIT_FNAMES[@]}"; do unset -f "${f}" &>/dev/null ; done

  # Ensure testing functions
  . "${SNIP_TEST_RUNNER_DIR}/src/lib/shlib/test.sh"

  # Ensure function with deps
  declare tmp; tmp="${SNIP_TEST_RUNNER_DIR}/tmp/tests/$(basename -- "${BASH_SOURCE[2]}")"
  # shellcheck disable=SC1090
  . "${tmp}"
}

# shellcheck disable=SC2034
declare SHLIB_TEXT_FIXTURES_DIR="${SNIP_TEST_RUNNER_DIR}/tests/fixture"

# Add common fixtures
. "${SHLIB_TEXT_FIXTURES_DIR}/common.sh"

declare START_7vXdRl9nbm; START_7vXdRl9nbm="$(date +%s.%2N)"
declare SUITES_7vXdRl9nbm=0
declare f_7vXdRl9nbm; for f_7vXdRl9nbm in "${SNIP_TEST_FILES[@]}"; do
  (( SUITES_7vXdRl9nbm++ ))
  {
    declare tmp_7vXdRl9nbm; tmp_7vXdRl9nbm="${SNIP_TEST_RUNNER_DIR}/tmp/tests/$(basename -- "${f_7vXdRl9nbm}")"

    declare block; block="$(
      grep -m1 -A99 '{.*#\s*{{\s*SNIP_SHLIB\s*}}\s*$' "${f_7vXdRl9nbm}" \
      | grep -m1 -B99 '}.*#\s*{{\s*SNIP_SHLIB\s*}}\s*$'
    )" && {
      mkdir -p "$(dirname -- "${tmp_7vXdRl9nbm}")"
      echo "${block}" > "${tmp_7vXdRl9nbm}"
      SNIP_LOCAL=true "${SNIP_TEST_RUNNER_DIR}/snippet.sh" "${tmp_7vXdRl9nbm}"
    }
  }

  # shellcheck disable=SC1090
  . "${f_7vXdRl9nbm}"
done
declare END; END="$(date +%s.%2N)"

declare -i RC=0
declare RESULT=SUCCESS
[[ ${SHLIB_TEST_STATS[KO]} -lt 1 ]] || {
  RESULT=FAILURE
  RC=1
}

text_fmt <<< "
  OK:     ${SHLIB_TEST_STATS[OK]}
  KO:     ${SHLIB_TEST_STATS[KO]}
  SKIP:   ${SHLIB_TEST_STATS[SKIP]}
  SUITES: ${SUITES_7vXdRl9nbm}
  TIME:   $(bc <<< "${END} - ${START_7vXdRl9nbm}")
" | text_prefix '  ' | text_wrap "# { ${RESULT}" "# } ${RESULT}"

exit "${RC}"

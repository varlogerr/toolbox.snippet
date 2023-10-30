meta_deps()   { _meta_print "${@}"; }
meta_info()   { _meta_print "${@}"; }
meta_usage()  { _meta_print "${@}"; }
meta_env()    { _meta_print "${@}"; }
meta_opts()   { _meta_print "${@}"; }
meta_args()   { _meta_print "${@}"; }
meta_rc()     { _meta_print "${@}"; }
meta_demo()   { _meta_print "${@}"; }
meta_more()   { _meta_print "${@}"; }

# Serves to be a catch-all in case there is no meta_* to halt
# the function or to bring self invocation line.
meta_end() {
  # Catch all, signifying that queried data is not found
  if [[ ${FUNCNAME[2]} == meta_query ]]; then
    # shellcheck disable=SC2154
    [[ "${META_REQ_wxjZHSo1YP8A5T6}" == "${FUNCNAME[0]}" ]] || exit

    echo "${BASH_LINENO[0]}"; exit
  fi
}

# The function itself must not be queried
meta_build_annotation() {
  meta_deps import_nl text_prefix log_fuck escape_sed_repl \
            text_fmt

  declare fname="${1}"
  declare -A SEGMENTS=(
    # [NAME]=PRINT_TITLE
    [info]=''
    [usage]='USAGE'
    [env]='ENV'
    [opts]='OPTIONS'
    [args]='ARGUMENTS'
    [rc]='RETURN CODES'
    [demo]='DEMO'
    [more]=''
  )
  declare -a TYPES_ORDERED=(info usage env opts args rc demo more)

  declare NL; import_nl NL

  declare bucket
  declare -i rc
  declare type; for type in "${TYPES_ORDERED[@]}"; do
    bucket="$(meta_query "${fname}" "${type}")" || {
      rc=$?; [[ ${rc} -gt 1 ]] && {
        log_fuck <<< "Undefined function: '${fname}'"
        return 2
      }

      # Remove the segment as there is nothing for it
      SEGMENTS["${type}"]=''
      continue
    }

    bucket="$(text_fmt <<< "${bucket}")"
    [[ -n "${SEGMENTS[${type}]}" ]] && {
      bucket="$(text_prefix '  ' <<< "${bucket}")"
      SEGMENTS["${type}"]+="${SEGMENTS[$type]:+:${NL}}"
    }

    SEGMENTS["${type}"]+="${bucket}"
  done

  declare fname_repl; fname_repl="$(escape_sed_expr <<< "${fname}")"
  declare text
  declare -i ctr=0
  declare type; for type in "${TYPES_ORDERED[@]}"; do
    text="${SEGMENTS[$type]}"
    [[ -n "${text}" ]] || continue

    [[ ${ctr} -gt 0 ]] && printf -- '%s' "${SHLIB_NL}"
    printf -- '%s' "${text}${SHLIB_NL}"

    (( ctr++ ))
  done | sed 's/{{\s*CMD\s*}}/'"${fname_repl}"'/'
}

meta_build_fdef() (
  declare fname="${1}"

  # Ensure meta_end in the function
  _meta_inject_end "${fname}"

  declare fdef; fdef="$(declare -f "${fname}")" &>/dev/null || {
    log_fuck <<< "Undefined function: '${fname}'"
    return 2
  }

  # shellcheck disable=SC2016
  declare meta_end_line
  # shellcheck disable=SC1090
  meta_end_line="$(. <(echo "${fdef}"); meta_query "${fname}" end)" || {
    echo "${fdef}"
    return
  }

  declare first_meta_line; first_meta_line="$(
    grep -m1 -n '^\s\+meta_[^ ]\+\(\s\+.*\)\?\s*;\?\s*$' <<< "${fdef}" \
    | grep -o '^[0-9]\+'
  )"

  fdef="$(
    head -n $(( first_meta_line - 1 )) <<< "${fdef}"
    echo ':'
    tail -n +$(( meta_end_line + 1 )) <<< "${fdef}"
  )"

  (
    # shellcheck disable=SC1090
    . <(echo "${fdef}")
    declare -f "${fname}"
  )
)

# The function itself must not be queried
#
# RC:
#   0 - All is fine
#   1 - No meta type data is available
#   2 - Requested function is not available
meta_query() (
  declare fname="${1}" meta_type="${2}"
  declare -F "${fname}" &>/dev/null || return 2

  # Ensure meta_end in the function
  _meta_inject_end "${fname}"

  # Call function with some dummy stdin for the same reason as
  # why `false` is returned in the end of the function
  META_REQ_wxjZHSo1YP8A5T6="${META_REQ_wxjZHSo1YP8A5T6-meta_${meta_type}}" \
    "${fname}" <<< ""

  # We only can get here if nothing caught the query, i.e. functions without
  # both `meta_${meta_type}` and `meta_end` including functions without meta at all.
  # In case some of the `meta_*` catches the query in the previous call, current
  # function halts before reaching here
  false
)

_meta_inject_end() {
  declare fname="${1}"
  declare fdef; fdef="$(declare -f "${fname}" 2>/dev/null)" || return

  grep -qx '\s\+meta_end\(\s.*\)\?\s*;\?\s*' <<< "${fdef}" && return

  # shellcheck disable=SC2001
  # shellcheck disable=SC1090
  . <(sed '2 s/\s*{/{ meta_end;/' <<< "${fdef}")
}

_meta_print() {
  # expected 'meta_query'
  declare caller="${FUNCNAME[3]}"
  declare upstream="${FUNCNAME[1]}"
  # '-3' index can provoke 'bad array subscript' error

  # Just return if it's a wrong meta type or direct function call
  [[ (
    "${caller}" == meta_query \
    && "${upstream}" == "${META_REQ_wxjZHSo1YP8A5T6}"
  ) ]] || return 0

  # No data, exit 1
  [[ $# -gt 0 ]] || exit 1

  declare data; data="$(printf -- '%s\n' "${@}")"
  [[ "${data:0:1}" == '@' ]] && {
    # Follow the reference
    declare ref="${data:1}"

    # Avoid circular reference
    [[ ${#META_STACK_wxjZHSo1YP8A5T6[@]} -gt 0 ]] || declare -a META_STACK_wxjZHSo1YP8A5T6
    [[ " ${META_STACK_wxjZHSo1YP8A5T6[*]} " != *" ${ref} "* ]] || exit
    META_STACK_wxjZHSo1YP8A5T6+=("${ref}")

    declare ref_data; ref_data="$(
      META_REQ_wxjZHSo1YP8A5T6="${upstream}" "${caller}" "${ref}"
    )" && data="${ref_data}"
  }

  printf -- '%s\n' "${data}"; exit
}

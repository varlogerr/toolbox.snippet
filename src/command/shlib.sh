#
# Relies on functionality added by `snippet.sh`
#

shlib_gen_dummy() {
  text_fmt <<< '
    dummy() {
      { # META
        # meta_deps
        # meta_info
        # meta_usage
        # meta_env
        # meta_opts
        # meta_args
        # meta_rc
        # meta_demo
        # meta_more
        meta_end
      } # META

      # Put some action here
      :
    }
  '
}

shlib_filter_public_fnames() {
  declare -a forbidden_suffix=(
    _ .meta meta_ .test shlib_test_
  )
  declare grep_script; grep_script="^\\($(
    printf -- '%s\n' "${forbidden_suffix[@]}" | escape_sed_expr \
    | tr '\n' '|' | sed -e 's/|$//' -e 's/|/\\|/g'
  )\\)"

  [[ ${#RO_FNAMES[@]} -gt 0 ]] && grep_script+="${SHLIB_NL}$(
    printf -- '%s\n' "${RO_FNAMES[@]}" | sed 's/^\(.\+\)$/^\1$/'
  )"

  grep -vf <(echo "${grep_script}") | grep '.'
}

shlib_modules_topology() {
  declare filter=cat
  ${1-false} && filter=shlib_filter_public_fnames

  declare m; for m in "${!SNIP_MODULE_TO_FNAMES[@]}"; do
    echo "${m}"
  done | sort -n | while read -r m; do
    echo "${m}"
    echo "${SNIP_MODULE_TO_FNAMES[$m]}" | grep '' | sort -n
  done | "${filter}"
}

shlib_print_help() {
  declare self; self="$(basename -- "${0}" 2>/dev/null)"
  self="${self:-snippet.sh}"

  text_fmt <<< "
    Generate snippets in place of placeholders.

    USAGE:
      [SNIP_BRANCH=master] [SNIP_DEBUG=true] ${self} TARGET_FILE
      [SNIP_BRANCH=master] [SNIP_DEBUG=true] ${self} OPTIONS

    ENV:
      SNIP_GRANCH   Branch to work with
      SNIP_DEBUG    Run in debug mode
      SNIP_LOCAL    (bool) For local development, ignores SNIP_BRANCH

    OPTIONS:
      -?, -h, --help  Print this help
      -l, --list      List modules and functions
      --dummy-func    Generate dummy function to stdout
  "
}

declare TARGET
while [[ -n ${1+x} ]]; do
  case "${1}" in
    -\?|-h|--help ) shlib_print_help; exit ;;
    -l|--list     )
      declare pubonly=true
      [[ "${2}" == '!' ]] && pubonly=false
      shlib_modules_topology ${pubonly}
      exit
      ;;
    --dummy-func  ) shlib_gen_dummy; exit ;;
    *             ) TARGET="${1}" ;;
  esac

  shift
done

[[ -n "${TARGET+x}" ]] || {
  log_fuck <<< "TARGET required."
  return 2
}

####################
#### SNIP_SHLIB ####
####################

# First and last lines of snippet block in target file
shlib_placeholder_lines() (
  declare target="${1}"

  declare content; content="$(
    "${SNIP_DBG_CMD[@]}"; cat -- "${target}" 2>/dev/null
  )" || return 1

  declare ptn_common='.\+#\s*{{\s*SNIP_SHLIB\s*}}\s*'
  declare ptn_start='.*{'"${ptn_common}"
  declare ptn_end='[0-9]\+-.*}'"${ptn_common}"

  ("${SNIP_DBG_CMD[@]}"
    grep -n -x -m1 -A99999 "${ptn_start}" <<< "${content}" \
    | grep -x -m1 -B99999 "${ptn_end}" | sed -n '1p;$p' | grep -o '^[0-9]\+'
  )
)

shlib_placeholder_default_txt() {
  shlib_modules_topology true | grep '^\.' | text_prefix '  # @' \
  | text_wrap '{ : # {{ SNIP_SHLIB }}' '} # {{ SNIP_SHLIB }}'
}

shlib_get_import_items() {
  declare ptn='^\s*#\s*@\(.\+\)'
  ("${SNIP_DBG_CMD[@]}"
    sed -n "${2},${3}p" -- "${1}" | tail -n +2 | grep -m1 -B99999 -v "${ptn}" \
    | grep "${ptn}" | sed 's/'"${ptn}"'/\1/' | sort -n | uniq
  )
}

shlib_items_to_fnames() {
  declare item; while read -r item; do
    if grep -q '^\.' <<< "${item}"; then
      grep -qxFf <(printf -- '%s\n' "${!SNIP_MODULE_TO_FNAMES[@]}") <<< "${item}" && {
        printf -- '%s\n' "${SNIP_MODULE_TO_FNAMES[$item]}"
      } || {
        log_warn <<< "Invalid item: ${item}"
      }
    else
      grep -xFf <(printf -- '%s\n' "${SNIP_MODULE_TO_FNAMES[@]}") <<< "${item}" || {
        # TODO: log warn
        log_warn <<< "Invalid item: ${item}"
      }
    fi
  done | sort -n | uniq
}

shlib_fnames_append_deps() {
  declare bucket; bucket="$(cat)"
  declare all="${bucket}"
  declare new
  declare item; while [[ -n "${bucket}" ]] && item="$(head -n 1 <<< "${bucket}" | grep '')"; do
    # Shift the top element
    bucket="$(tail -n +2 <<< "${bucket}")"

    # Append only the ones that are not currently in the bucket
    new="$(set -o pipefail
      meta_query "${item}" deps | grep -vf <(printf -- '%s' "${all}")
    )" && {
      all+="${all:+${SHLIB_NL}}${new}"
      bucket+="${bucket:+${SHLIB_NL}}${new}"
    }

    printf -- '%s\n' "${item}"
  done | sort -n | uniq
}

shlib_fnames_to_annoteted_fdefs() {
  declare -i ctr=0
  declare fname; while read -r fname; do
    [[ ${ctr} -gt 0 ]] && echo
    meta_build_annotation "${fname}" | text_prefix '# '
    meta_build_fdef "${fname}"
    (( ctr++ ))
  done
}

shlib_update_target() {
  declare update
  if ! update="$(cat | grep '')"; then
    return
  fi

  declare target="${1}"
  declare target_txt; target_txt="$(cat -- "${target}")"
  declare -i start="${2}" end="${3}"

  declare req_lines; req_lines="$(
    sed -n "$(( start + 1 )),${end}p" <<< "${target_txt}" \
    | grep -v -m1 -B99999 '^\s*#\s*@' | sed '$ d'
  )"

  declare offset; offset="$(head -n 1 <<< "${req_lines}" | grep -o '^\s*')"

  {
    head -n "${start}" -- <<< "${target_txt}"
    echo "${req_lines}"
    echo; echo "${update}" | text_fmt | text_prefix "${offset}"
    tail -n +"${end}" -- <<< "${target_txt}"
  } | tee -- "${target}" >/dev/null
}

declare -a PH_LINES
declare bucket; bucket="$(shlib_placeholder_lines "${TARGET}")" && {
  mapfile -t PH_LINES <<< "${bucket}"
}

if [[ ${#PH_LINES[@]} -gt 0 ]]; then
  shlib_get_import_items "${TARGET}" "${PH_LINES[@]}" \
  | shlib_items_to_fnames | shlib_filter_public_fnames | shlib_fnames_append_deps \
  | shlib_fnames_to_annoteted_fdefs | shlib_update_target "${TARGET}" "${PH_LINES[@]}"
else
  {
    echo
    shlib_placeholder_default_txt
  } | ("${SNIP_DBG_CMD[@]}"; tee -a -- "${TARGET}" >/dev/null)
fi

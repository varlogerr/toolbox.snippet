#!/usr/bin/env bash

# Always here version placeholder
declare SNIP_VERSION='v20231106-d49623b' # {{ SNIP_VERSION /}}

declare -A SNIP_CONF=(
  [content_url]=https://raw.githubusercontent.com
  [git_repo]=varlogerr/toolbox.snippet
)

#################
#### INITIAL ####
#################

declare SNIP_PROJ_DIR; SNIP_PROJ_DIR="$(dirname -- "${0}")"
declare SNIP_TMP_DIR=/tmp/RnRj81yw7z.snip

declare SNIP_SESSION_ID; SNIP_SESSION_ID="$(
  tr -dc '[:alnum:]' </dev/urandom | fold -w 10 | head -n 1
)"

# For tests and local development
declare SNIP_LOCAL="${SNIP_LOCAL}"
[[ "${SNIP_LOCAL,,}" =~ ^(true|yes|y|1)$ ]] && SNIP_LOCAL=true || SNIP_LOCAL=false

# Get repo where to get the source
snip_repo_git_repo() {
  declare default='varlogerr/toolbox.snippet'

  : \
  && cat -- "${SNIP_PROJ_DIR}/.snip.dev" &>/dev/null \
  && git remote get-url origin 2>/dev/null | tr ':' '/' \
    | rev | cut -d'/' -f-2 | rev | sed 's/\.git$//' | grep '.' \
  || printf -- '%s\n' "${default}"
}

# Get branch where to get the source
snip_repo_git_branch() {
  declare default="${SNIP_VERSION:-master}"

  : \
  && cat -- "${SNIP_PROJ_DIR}/.snip.dev" &>/dev/null \
  && git rev-parse --symbolic-full-name --abbrev-ref HEAD 2>/dev/null | grep '.' \
  || printf -- '%s\n' "${default}"
}

snip_repo_tmp_fetch() {
  ${SNIP_LOCAL} && {
    printf -- '%s\n' "$(dirname -- "${0}")"
    return
  }

  # Select the download tool
  declare -a DL_TOOL=(curl -kLsS)
  "${DL_TOOL[@]}" --version &>/dev/null || {
    DL_TOOL=(wget -qO -)
    "${DL_TOOL[@]}" --version &>/dev/null
  } || {
    echo "[FUCK] Can't detect download tool." >&2
    return 1
  }; DL_TOOL+=(--)

  declare src_dir="${SNIP_TMP_DIR}/source"

  cat -- "${src_dir}/${SNIP_SESSION_ID}" &>/dev/null || {
    rm -rf -- "${src_dir}"

    mkdir -p -- "${src_dir}"
    touch "${src_dir}/${SNIP_SESSION_ID}"

    declare dl_url; dl_url="$(
      printf -- 'https://api.github.com/repos/%s/tarball/%s?%s' \
        "$(snip_repo_git_repo)" "$(snip_repo_git_branch)" "$(date +%s)"
    )"

    "${DL_TOOL[@]}" "${dl_url}" | tar -xzf - -C "${src_dir}" || return 1
    mv "${src_dir}"/*/* "${src_dir}"/
  }

  printf -- '%s\n' "${src_dir}"
}

_snip_import_ro_fnames() {
  declare fnames; fnames="$(
    declare -Fr | rev | cut -d' ' -f1 | rev | grep ''
  )" && mapfile -t RO_FNAMES <<< "${fnames}"
}

# Imports SNIP_MODULE_TO_FNAMES, SNIP_FNAME_TO_FDEF and SNIP_CMD_TO_FILE assoc
snip_import_env() {
  declare -p SNIP_MODULE_TO_FNAMES 2>/dev/null | grep -q '^declare\s\+-A' || {
    unset SNIP_MODULE_TO_FNAMES
    declare -gA SNIP_MODULE_TO_FNAMES
  }
  declare -p SNIP_FNAME_TO_FDEF 2>/dev/null | grep -q '^declare\s\+-A' || {
    unset SNIP_FNAME_TO_FDEF
    declare -gA SNIP_FNAME_TO_FDEF
  }
  declare -p SNIP_CMD_TO_FILE 2>/dev/null | grep -q '^declare\s\+-A' || {
    unset SNIP_CMD_TO_FILE
    declare -gA SNIP_CMD_TO_FILE
  }

  declare tmp_core; tmp_core="$(snip_repo_tmp_fetch)/src" || return

  declare -a RO_FNAMES
  _snip_import_ro_fnames

  declare m_name bucket
  declare m_path; for m_path in "${tmp_core}/lib/shlib"/*.sh; do
    m_name="$(basename -s '.sh' -- "${m_path}")"

    bucket="$(
      while read -r f; do
        unset -f "${f}" &>/dev/null
      done < <(declare -F | rev | cut -d' ' -f1 | rev)

      # shellcheck disable=SC1090
      . "${m_path}"

      names="$(
        declare -F | rev | cut -d' ' -f1 | rev | grep -vFx <(printf -- '%s\n' "${RO_FNAMES[@]}")
      )" && {
        echo "${names}"
        # Fnames separator
        echo '==='
        while read -r fname; do
          # Prefix fdef with ':'
          declare -f "${fname}" | sed 's/^/:/'
          # Fdefs separated by fnames
          echo "${fname}"
        done <<< "${names}"
      }
    )" && {
      declare -i b_len; b_len="$(wc -l <<< "${bucket}")"
      SNIP_MODULE_TO_FNAMES[".${m_name}"]="$(grep -m1 -B "${b_len}" '^===' <<< "${bucket}" | sed '$ d')"

      bucket="$(grep -m1 -A "${b_len}" '===' <<< "${bucket}" | sed '1 d')"
      declare fname
      declare b_item; while b_item="$(set -o pipefail
        grep -m1 -B "${b_len}" '^[^:]' <<< "${bucket}"
      )"; do
        fname="$(grep '^[^:]' <<< "${b_item}")"
        SNIP_FNAME_TO_FDEF["${fname}"]="$(sed -e '/^[^:]/d' -e 's/^://' <<< "${b_item}")"
        bucket="$(grep -m1 -A "${b_len}" '^[^:]' <<< "${bucket}" | tail -n +2 )"
      done
    }
  done

  declare p_name
  declare p_path; for p_path in "${tmp_core}/command"/*.sh; do
    p_name="$(basename -s '.sh' -- "${p_path}")"

    SNIP_CMD_TO_FILE["${p_name}"]="$(cat -- "${p_path}")" || return
  done
}

{
  declare -A SNIP_MODULE_TO_FNAMES SNIP_FNAME_TO_FDEF SNIP_CMD_TO_FILE
  snip_import_env || exit

  # Load modules
  # shellcheck disable=SC1090
  . <(printf -- '%s\n' "${SNIP_FNAME_TO_FDEF[@]}")

  # shellcheck disable=SC2034
  declare SHLIB_NL; import_nl
}

# All before here can be sourced
(return 0 &>/dev/null) && return

################
#### ACTION ####
################

_iife_opts() {
  while [[ -n "${1}" ]]; do
    case "${1}" in
      -v|--version )
        echo "${SNIP_VERSION}"
        exit
        ;;
    esac

    shift
  done
}; _iife_opts "${@}"; unset _iife_opts

# shellcheck disable=SC1090
. <(cat <<< "${SNIP_CMD_TO_FILE[shlib]}") || exit

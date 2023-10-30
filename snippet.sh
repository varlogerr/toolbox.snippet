#!/usr/bin/env bash

# Always here version placeholder
declare SNIP_VERSION='dev' # {{ SNIP_VERSION /}}

declare -A SNIP_CONF=(
  [content_url]=https://raw.githubusercontent.com
  [git_repo]=varlogerr/toolbox.snippet
)

#################
#### INITIAL ####
#################

declare SNIP_BRANCH="${SNIP_BRANCH:-${SNIP_VERSION}}"
declare SNIP_DEBUG="${SNIP_DEBUG:-false}"

# For tests and local development
declare SNIP_LOCAL="${SNIP_LOCAL}"
[[ "${SNIP_LOCAL,,}" =~ ^(true|yes|y|1)$ ]] \
&& SNIP_LOCAL=true || SNIP_LOCAL=false

declare -a SNIP_DBG_CMD=(true) SNIP_UNDBG_CMD=(true)
[[ "${SNIP_DEBUG,,}" =~ ^(true|yes|y|1)$ ]] && {
  SNIP_DBG_CMD=(set -x)
  SNIP_UNDBG_CMD=(set +x)
}

_snip_import_ro_fnames() {
  declare fnames; fnames="$(
    declare -Fr | rev | cut -d' ' -f1 | rev | grep ''
  )" && mapfile -t RO_FNAMES <<< "${fnames}"
}

snip_dl_to_stdout() {
  declare -a dl_tool=(curl -kLsS)

  "${dl_tool[@]}" --version &>/dev/null || {
    dl_tool=(wget -qO -)
    "${dl_tool[@]}" --version &>/dev/null
  } || {
    echo "Can't detect download tool." >&2
    return 1
  }

  "${dl_tool[@]}" -- "${1}"
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

  declare -a CLEAN=(:)
  declare tmp_core; tmp_core="$(dirname -- "${0}")/src"

  ! ${SNIP_LOCAL} && {
    declare DL_CORE_URL; DL_CORE_URL="$(printf -- '/%s' \
      "${SNIP_CONF[content_url]}" "${SNIP_CONF[git_repo]}" \
      "${SNIP_BRANCH}" "src/dl-core.sh?$(date +%s)" \
    )"; DL_CORE_URL="${DL_CORE_URL:1}"

    # Select the download tool
    declare -a DL_TOOL=(curl -kLsS)
    "${DL_TOOL[@]}" --version &>/dev/null || {
      DL_TOOL=(wget -qO -)
      "${DL_TOOL[@]}" --version &>/dev/null
    } || {
      echo "Can't detect download tool." >&2
      return 1
    }; DL_TOOL+=(--)

    declare tmp_core; tmp_core="$(set -o pipefail; "${SNIP_DBG_CMD[@]}"
      "${DL_TOOL[@]}" "${DL_CORE_URL}" \
      | SNIP_GIT_REPO="${SNIP_CONF[git_repo]}" SNIP_BRANCH="${SNIP_BRANCH}" SNIP_DEBUG="${SNIP_DEBUG}" bash
    )" || return

    declare -a CLEAN=(rm -rf "${tmp_core}")
  }

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
      { "${SNIP_DBG_CMD[@]}"; . "${m_path}"; { "${SNIP_UNDBG_CMD[@]}"; } &>/dev/null; }

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

    SNIP_CMD_TO_FILE["${p_name}"]="$("${SNIP_DBG_CMD[@]}"; cat -- "${p_path}")" || return
  done

  ("${SNIP_DBG_CMD[@]}"; "${CLEAN[@]}"); return 0
}

{
  declare -A SNIP_MODULE_TO_FNAMES SNIP_FNAME_TO_FDEF SNIP_CMD_TO_FILE
  snip_import_env || exit

  "${SNIP_DBG_CMD[@]}"
    # Load modules
    # shellcheck disable=SC1090
    . <({ "${SNIP_UNDBG_CMD[@]}"; } 2>/dev/null; printf -- '%s\n' "${SNIP_FNAME_TO_FDEF[@]}")
  { "${SNIP_UNDBG_CMD[@]}"; } 2>/dev/null

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

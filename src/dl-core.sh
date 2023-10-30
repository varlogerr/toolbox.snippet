snip_dl_core() {
  declare \
    SNIP_GIT_REPO="${SNIP_GIT_REPO:-varlogerr/toolbox.snippet}" \
    SNIP_BRANCH="${SNIP_BRANCH:-master}" \
    SNIP_DEBUG="${SNIP_DEBUG:-false}"

  declare API_DL_URL; API_DL_URL="$(printf -- '/%s' \
    https://api.github.com/repos/varlogerr/toolbox.snippet/tarball \
    "${SNIP_BRANCH}?$(date +%s)" \
  )"; API_DL_URL="${API_DL_URL:1}"

  declare dbg_cmd=(true)
  [[ "${SNIP_DEBUG,,}" =~ ^(true|yes|y|1)$ ]] && dbg_cmd=(set -x)

  declare tmp; tmp="$("${dbg_cmd[@]}"; mktemp -d)" || return

  # Select the download tool
  declare -a DL_TOOL=(curl -kLsS)
  "${DL_TOOL[@]}" --version &>/dev/null || {
    DL_TOOL=(wget -qO -)
    "${DL_TOOL[@]}" --version &>/dev/null
  } || {
    echo "Can't detect download tool." >&2
    return 1
  }; DL_TOOL+=(--)

  # https://unix.stackexchange.com/a/6395
  (set -o pipefail; shopt -s dotglob; "${dbg_cmd[@]}"
    mkdir -p -- "${tmp}/snip-core" \
    && "${DL_TOOL[@]}" "${API_DL_URL}" | tar -xzf - -C "${tmp}/snip-core" \
    && cp -r -- "${tmp}/snip-core"/*/src/. "${tmp}"
  ) || { ("${dbg_cmd[@]}"; rm -rf "${tmp}"); return 1; }

  ("${dbg_cmd[@]}"; rm -rf "${tmp}/snip-core" &>/dev/null)
  printf -- "%s\n" "${tmp}"
}

# All before here can be sourced as library
(return 0 &>/dev/null) && return

snip_dl_core

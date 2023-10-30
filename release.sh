#!/usr/bin/env bash

declare SNIP_RELEASE_RUNNER_DIR; SNIP_RELEASE_RUNNER_DIR="$(dirname -- "${0}")"

declare -A SNIP_BIN=(
  [snippet]="${SNIP_RELEASE_RUNNER_DIR}/snippet.sh"
  [test]="${SNIP_RELEASE_RUNNER_DIR}/test.sh"
)

cat -- "${SNIP_BIN[snippet]}" "${SNIP_BIN[test]}" &>/dev/null || {
  log_fuck <<< "Can't detect snippet directory."
  exit 1
}

# shellcheck disable=SC1090
SNIP_LOCAL=true . "${SNIP_BIN[snippet]}"

snip_release_help() {
  declare SELF; SELF="$(basename -- "${0}" 2>/dev/null)"
  [[ -n "${SELF+x}" ]] || SELF="test.sh"

  text_fmt <(echo "
    Add version, tag and prepare for release.

    USAGE:
      ${SELF} [OPTION]...

      # Prepare release and follow the guidance
      ${SELF}

    OPTS:
      -?, -h, --help  Print this help
      --dry           Dry run
  ")
}

declare -A OPT=(
  [dry]=false
)
_iife_opts() {
  while [[ -n "${1}" ]]; do
    case "${1}" in
      -\?|-h|--help )
        snip_release_help
        exit
        ;;
      --dry         )
        OPT[dry]=true
        ;;
    esac

    shift
  done
}; _iife_opts "${@}"; unset _iife_opts

# https://stackoverflow.com/a/16925062
git rev-parse --is-inside-work-tree &>/dev/null || {
  log_fuck <<< "Not in git directory."
  exit 1
}

declare -a ERRBAG

git rev-parse --symbolic-full-name --abbrev-ref HEAD | grep -qFx 'master' || {
  ERRBAG+=('Not in master branch.')
}

# https://stackoverflow.com/a/25149786
git status --porcelain | grep -q '.' && {
  ERRBAG+=("All the changes must be committed.")
}

declare marker_rex='#\s*{{\s*SNIP_VERSION\s*\/}}\s*'

declare b; for b in "${SNIP_BIN[@]}"; do
  grep -q "${marker_rex}\$" -- "${b}" || {
    ERRBAG+=("Can't find VERSION placeholder in '${b}'.")
  }
done

[[ ${#ERRBAG[@]} -lt 1 ]] || {
  printf -- '%s\n' "${ERRBAG[@]}" | log_fuck
  exit 1
}

"${SNIP_BIN[test]}" || {
  echo
  log_fuck <<< "Can't release this unhealthy crap!!!"
  exit 1
}

declare VERSION; VERSION="$(printf -- 'v%s-%s' \
  "$(date '+%Y%m%d')" "$(git rev-parse --verify --short HEAD)"
)"

${OPT[dry]} && {
  echo

  text_fmt <<< "
    ===============================================
    ===== Ready for version ${VERSION} =====
    ===============================================
  " | log_info

  exit
}

sed -i 's/^.*\('"${marker_rex}"'\)$/'"declare SNIP_VERSION='${VERSION}' \1"'/' \
  "${SNIP_BIN[snippet]}" "${SNIP_BIN[test]}"

git co -am "Release: ${VERSION}"
git tag "${VERSION}"

sed -i 's/^.*\('"${marker_rex}"'\)$/'"declare SNIP_VERSION='dev' \1"'/' \
  "${SNIP_BIN[snippet]}" "${SNIP_BIN[test]}"

echo
# shellcheck disable=SC2016
text_fmt <<< '
  =======================
  ===== FINAL STEPS =====
  =======================

  1) `git push`
  2) `git push origin '"${VERSION}"'`

  Or revert the changes:

  1) `git checkout -- .`
  2) `git tag -d '"${VERSION}"'`
  3) `git reset --hard HEAD^`
' | log_info

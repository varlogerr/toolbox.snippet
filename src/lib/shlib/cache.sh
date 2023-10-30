cache_fs() {
  declare CACHE_DIR; CACHE_DIR="/tmp/3cgiVJBN6X.$(id -u).cache.shlib"

  { # META
    meta_info "Caches to '${CACHE_DIR}' directory (suffix depends on the UID)."
    meta_usage "
      {{ CMD }} KEY FILE...      # Put & get cache
      {{ CMD }} KEY - <<< TEXT   # Put & get cache
      {{ CMD }} KEY              # Get cache
    "
    meta_end
  } # META

  declare -i MAX_SIZE=20480

  declare key="${1}"
  key="$(printf -- '%s' "${key}" | sha1sum | cut -d' ' -f 1)"
  declare DEST="${CACHE_DIR}/${key}"

  declare -a VAL=("${@:2}")

  [[ ${#VAL[@]} -gt 0 ]] || {
    cat -- "${DEST}" 2>/dev/null
    return $?
  }

  (
    (
      size="$(du -d 0 -- "${CACHE_DIR}" 2>/dev/null | grep -o -m 1 '^[0-9]\+')"
      [[ ${size:-0} -gt ${MAX_SIZE} ]] && rm -f "${CACHE_DIR}"/*
    ) &
  ) &>/dev/null

  mkdir -p "${CACHE_DIR}" 2>/dev/null
  cat -- "${VAL[@]}" | tee -- "${DEST}" 2>/dev/null

  return 0
}

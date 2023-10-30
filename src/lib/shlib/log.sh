log_sth() {
  declare PREFIX; PREFIX="$(basename -- "${0}" 2>/dev/null)"
          PREFIX="${PREFIX:-snippet.sh}: "

  { # META
    meta_deps text_prefix
    meta_info "Logger."
    meta_env "
      SHLIB_LOG_PREFIX  Custom log prefix, defaults to executor
                        filename (currently '${PREFIX}')
    "
    meta_opts "
      --what  What to log
    "
    meta_usage "
      [SHLIB_LOG_PREFIX] {{ CMD }} [--what=''] FILE...
      [SHLIB_LOG_PREFIX] {{ CMD }} [--what=''] <<< TEXT
    "
    meta_demo "
      # Print with default prefix
      {{ CMD }} --what=ERROR 'Oh, no!' # STDERR: ${PREFIX}[ERROR] Oh, no!
    "
    meta_end
  } # META

  { # ARGS
    declare -a ARG_FILE
    declare -A OPT=(
      [_endopts]=false
      [what]=''
    )
    declare arg; while [[ -n "${1+x}" ]]; do
      ${OPT[_endopts]} && arg='*' || arg="${1}"

      case "${arg}" in
        --        ) OPT[_endopts]=true ;;
        --what=*  ) OPT[what]="${1#*=}" ;;
        --what    ) OPT[what]="${2}"; shift ;;
        *         ) ARG_FILE+=("${1}") ;;
      esac

      shift
    done
  } # ARGS

  PREFIX="${SHLIB_LOG_PREFIX-${PREFIX}}"
  [[ -n "${OPT[what]}" ]] && PREFIX+="[${OPT[what]^^}] "

  cat -- "${ARG_FILE[@]}" | text_prefix "${PREFIX}" >&2
}

log_info() {
  { # META
    meta_deps log_sth
    meta_env '@log_sth'
    meta_usage "
      [SHLIB_LOG_PREFIX] {{ CMD }} FILE...
      [SHLIB_LOG_PREFIX] {{ CMD }} <<< TEXT
    "
    meta_end
  } # META

  log_sth --what=INFO -- "${@}"
}

log_warn() {
  { # META
    meta_deps log_sth
    meta_env '@log_sth'
    meta_usage '@log_info'
    meta_end
  } # META

  log_sth --what=WARN -- "${@}"
}

log_fuck() {
  { # META
    meta_deps log_sth
    meta_env '@log_sth'
    meta_usage '@log_info'
    meta_end
  } # META

  log_sth --what=FUCK -- "${@}"
}

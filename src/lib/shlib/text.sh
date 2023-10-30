text_ensure_nl() {
  { : # META
    meta_more '
      REFERENCES:
        * https://unix.stackexchange.com/a/31955
    '
    meta_end
  } # META

  # shellcheck disable=SC1003
  cat -- "${@}" | sed '$a\'
}

text_undecore() {
  { # META
    meta_deps escape_sed_expr
    meta_info "Undecorate text."
    meta_usage "
      {{ CMD }} [--symbol=','] FILE...
      {{ CMD }} [--symbol=','] <<< TEXT
    "
    meta_opts '
      --symbol  See demo
    '
    meta_demo '
      # * Remove blank and space-only lines
      # * Trim prepending spaces
      # * Remove prepending SYMBOL, but leave following spaces
      {{ CMD }} --symbol="%" <<< "
        Hello
       %  world
      "
      ```STDOUT
        Hello
          world
      ```
    '
    meta_end
  } # META

  { # ARGS
    declare -a ARG_FILE
    declare -A OPT=(
      [_endopts]=false
      [symbol]=','
    )
    declare arg; while [[ -n "${1+x}" ]]; do
      ${OPT[_endopts]} && arg='*' || arg="${1}"

      case "${arg}" in
        --          ) OPT[_endopts]=true ;;
        --symbol=*  ) OPT[symbol]="${1#*=}" ;;
        --symbol    ) OPT[symbol]="${2}"; shift ;;
        *           ) ARG_FILE+=("${1}") ;;
      esac

      shift
    done
  } # ARGS

  declare esc_symbol; esc_symbol="$(escape_sed_expr <<< "${OPT[symbol]}")"
  cat -- "${ARG_FILE[@]}" | sed -e 's/^\s\+//' \
    -e '/^$/d' -e 's/^'"${esc_symbol}"'//' -e 's/\s\+$//'
}

text_prefix() {
  { # META
    meta_deps escape_sed_expr
    meta_info "Prefix text."
    meta_usage "
      {{ CMD }} PREFIX FILE...
      {{ CMD }} [PREFIX=''] <<< TEXT
    "
    meta_demo "{{ CMD }} '[pref] ' <<< 'My text.'  # STDOUT: [pref] My text."
    meta_end
  } # META

  declare prefix="${1}"
  declare escaped; escaped="$(escape_sed_expr <<< "${prefix}")"
  cat -- "${@:2}" | sed 's/^/'"${escaped}"'/'
}

text_fmt() {
  { # META
    meta_info "Format text."
    meta_end
  } # META

  declare text; text="$(cat -- "${@}")" || return
  declare -i t_lines; t_lines="$(wc -l <<< "${text}")"

  # Remove blank lines from the beginning end and
  declare -a rm_blanks=(grep -m1 -A "${t_lines}" -vx '\s*')
  text="$("${rm_blanks[@]}" <<< "${text}" \
    | tac | "${rm_blanks[@]}" | tac | grep '')" || return 0

  # Calculate first line offset, trim it from other lines end trim
  # spaces from ends of lines
  declare offset; offset="$(sed -e '1!d' -e 's/^\(\s*\).*/\1/' <<< "${text}" | wc -m)"
  sed -e 's/^\s\{0,'$(( offset - 1 ))'\}//' -e 's/\s\+$//' <<< "${text}"
}

text_prepend() {
  { # META
    meta_deps escape_sed_repl
    meta_info "Prepend text with PREPENDIX string."
    meta_usage "
      {{ CMD }} PREPENDIX FILE...
      {{ CMD }} [PREPENDIX=''] <<< TEXT
    "
    meta_end
  } # META

  declare filter=(cat)
  [[ -n "${1+x}" ]] && {
    declare PREPENDIX; PREPENDIX="$(escape_sed_repl <<< "${1}")"
    filter=(sed '1 s/^/'"${PREPENDIX}"'\n/')
  }

  cat -- "${@:2}" | "${filter[@]}"
}

text_append() {
  { # META
    meta_deps escape_sed_repl
    meta_info "Append APPENDIX string to text."
    meta_usage "
      {{ CMD }} APPENDIX FILE...
      {{ CMD }} [APPENDIX] <<< TEXT
    "
    meta_end
  } # META

  declare filter=(cat)
  [[ -n "${1+x}" ]] && {
    declare APPENDIX; APPENDIX="$(escape_sed_repl <<< "${1}")"
    filter=(sed '$ s/$/\n'"${APPENDIX}"'/')
  }

  cat -- "${@:2}" | "${filter[@]}"
}

text_wrap() {
  { # META
    meta_deps text_prepend text_append
    meta_info "Wrap text."
    meta_usage "
      {{ CMD }} HEAD TAIL FILE...
      {{ CMD }} [HEAD [TAIL]] <<< TEXT
    "
    meta_demo '
      {{ CMD }} "==foo==" <<< BAR
      ```STDOUT
        ==foo==
        BAR
      ```
    '
    meta_end
  } # META

  cat -- "${@:3}" | text_prepend "${@:1:1}" | text_append "${@:2:1}"
}

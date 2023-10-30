_escape_dummy() {
  meta_usage  "
    {{ CMD }} FILE...
    {{ CMD }} <<< TEXT
  "
  meta_end
}

escape_printf() {
  { # META
    meta_info "Escape printf FORMAT string."
    meta_usage '@_escape_dummy'
    meta_more "
      REFERENCES:
        * https://unix.stackexchange.com/a/552358
    "
    meta_end
  } # META

  cat -- "${@}" | sed -e 's/[\\%]/&&/g'
}

escape_quote_double() {
  { # META
    meta_info "Escape double quotes."
    meta_usage "
      {{ CMD }} FILE...
      {{ CMD }} <<< TEXT
    "
    meta_demo "
      {{ CMD }} <<< 'Say \"Hi\"   # STDOUT: Say \\\"Hi\\\"
    "
    meta_end
  } # META

  cat -- "${@}" | sed -e 's/"/\\"/g'
}

escape_quote_single() {
  { # META
    meta_info "Escape single quotes."
    meta_usage "@escape_quote_double"
    meta_demo "
      {{ CMD }} <<< \"I'm Elvis\"   # STDOUT: I'\\''m Elvis
    "
    meta_end
  } # META

  cat -- "${@}" | sed -e "s/'/'\\\\''/g"
}

escape_sed_expr() {
  { # META
    meta_info "Escape sed expression for basic regex."
    meta_usage '@_escape_dummy'
    meta_more "
      REFERENCES:
        * https://stackoverflow.com/a/2705678
    "
    meta_end
  } # META

  cat -- "${@}" | sed 's/[]\/$*.^[]/\\&/g'
}

escape_sed_repl() {
  { # META
    meta_info "Escape sed replacement."
    meta_usage '@_escape_dummy'
    meta_more '@escape_sed_expr'
    meta_end
  } # META

  cat -- "${@}" | sed 's/[\/&]/\\&/g'
}

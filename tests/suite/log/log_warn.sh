{ : # {{ SNIP_SHLIB }}
  # @log_warn
} # {{ SNIP_SHLIB }}

THE_CMD=log_warn

custom_prefix() {
  # shellcheck disable=SC2034
  SHLIB_LOG_PREFIX='foobar ? '
  export SHLIB_LOG_PREFIX
}

shlib_test -t "Logs with default prefix (stdin)" \
    -e "$(basename -- "${0}"): [WARN] Hello" \
  ${THE_CMD} <<< 'Hello'

shlib_test -t "Logs with default prefix (file)" \
    -e "$(basename -- "${0}"): [WARN] Hello" \
  ${THE_CMD} <(echo 'Hello')

shlib_test -t "Logs with default prefix (multi-file)" \
    -e "$(basename -- "${0}"): [WARN] Hello" \
    -e "$(basename -- "${0}"): [WARN] world" \
  ${THE_CMD} <(echo 'Hello') <(echo 'world')

shlib_test -t "Logs with environment set prefix" \
    -b custom_prefix -e "foobar ? [WARN] Hello" \
  ${THE_CMD} <<< 'Hello'

shlib_test -t "Logs multiline" \
    -e "$(basename -- "${0}"): [WARN] Hello" \
    -e "$(basename -- "${0}"): [WARN] world" \
  ${THE_CMD} <(echo 'Hello'; echo 'world')

printf '' \
| shlib_test -t "Prints nothing on blank stdin" \
  ${THE_CMD}

shlib_test -t "Prints nothing on blank file" \
  ${THE_CMD} <(printf '')

shlib_test -t "Gets stuck on no FILE / TEXT" \
    -E -b fake_cat_stuck -a check_cat_stuck \
  ${THE_CMD}

{ : # {{ SNIP_SHLIB }}
  # @log_sth
} # {{ SNIP_SHLIB }}

THE_CMD=log_sth

custom_prefix() {
  # shellcheck disable=SC2034
  SHLIB_LOG_PREFIX='foobar ? '
  export SHLIB_LOG_PREFIX
}

shlib_test -t "Logs with defaults (stdin)" \
    -e "$(basename -- "${0}"): Hello" \
  ${THE_CMD} <<< 'Hello'

shlib_test -t "Logs with defaults (file)" \
    -e "$(basename -- "${0}"): Hello" \
  ${THE_CMD} <(echo 'Hello')

shlib_test -t "Logs with empty WHAT (file)" \
    -e "$(basename -- "${0}"): Hello" \
  ${THE_CMD} --what '' <<< 'Hello'

shlib_test -t "Logs with uppercase custom WHAT (--what '...')" \
    -e "$(basename -- "${0}"): [FOO] Hello" \
  ${THE_CMD} --what foo <<< 'Hello'

shlib_test -t "Logs with uppercase custom WHAT (--what='...')" \
    -e "$(basename -- "${0}"): [FOO] Hello" \
  ${THE_CMD} --what=foo <<< 'Hello'

shlib_test -t "Logs with default prefix (multi-file)" \
    -e "$(basename -- "${0}"): Hello" \
    -e "$(basename -- "${0}"): world" \
  ${THE_CMD} <(echo 'Hello') <(echo 'world')

shlib_test -t "Logs with environment set prefix" \
    -b custom_prefix -e "foobar ? Hello" \
  ${THE_CMD} <<< 'Hello'

shlib_test -t "Logs multiline" \
    -e "$(basename -- "${0}"): Hello" \
    -e "$(basename -- "${0}"): world" \
  ${THE_CMD} <(echo 'Hello'; echo 'world')

printf '' \
| shlib_test -t "Prints nothing on blank stdin" \
  ${THE_CMD} --what WONT_PRINT

shlib_test -t "Prints nothing on blank file" \
  ${THE_CMD} --what WONT_PRINT <(printf '')

shlib_test -t "Gets stuck on no FILE / TEXT" \
    -E -b fake_cat_stuck -a check_cat_stuck \
  ${THE_CMD}

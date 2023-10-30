{ : # {{ SNIP_SHLIB }}
  # @text_prefix
} # {{ SNIP_SHLIB }}

THE_CMD=text_prefix

shlib_test -t "Prefixes with nothing on empty PREFIX (stdin)" \
    -o 'foo' \
  ${THE_CMD} <<< 'foo'

shlib_test -t "Prefixes (stdin)" \
    -o 'foo bar' \
  ${THE_CMD} 'foo ' <<< 'bar'

shlib_test -t "Prefixes (file)" \
    -o 'foo bar' \
  ${THE_CMD} 'foo ' <(echo 'bar')

shlib_test -t "Prefixes (multi-file)" \
    -o 'foo bar' -o 'foo baz' \
  ${THE_CMD} 'foo ' <(echo 'bar') <(echo 'baz')

printf '' \
| shlib_test -t "Prints nothing on blank stdin" \
  ${THE_CMD}

shlib_test -t "Prints nothing on blank file" \
  ${THE_CMD} 'foo' <(printf '')

shlib_test -t "Gets stuck on no FILE / TEXT" \
    -E -b fake_cat_stuck -a check_cat_stuck \
  ${THE_CMD}

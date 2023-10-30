{ : # {{ SNIP_SHLIB }}
  # @text_prepend
} # {{ SNIP_SHLIB }}

THE_CMD=text_prepend

shlib_test -t "Doesn't change input on default PREPENDIX (stdin)" \
    -o 'foo' \
  ${THE_CMD} <<< 'foo'

shlib_test -t "Prepends (stdin)" \
    -o 'foo' -o 'bar' \
  ${THE_CMD} 'foo' <<< 'bar'

shlib_test -t "Prepends (file)" \
    -o 'foo' -o 'bar' \
  ${THE_CMD} 'foo' <(echo 'bar')

shlib_test -t "Prepends (multi-file)" \
    -o 'foo' -o 'bar' -o 'baz' \
  ${THE_CMD} 'foo' <(echo 'bar') <(echo 'baz')

printf '' \
| shlib_test -t "Prints nothing on blank stdin" \
  ${THE_CMD}

shlib_test -t "Prints nothing on blank file" \
  ${THE_CMD} 'foo' <(printf '')

shlib_test -t "Gets stuck on no FILE / TEXT" \
    -E -b fake_cat_stuck -a check_cat_stuck \
  ${THE_CMD}

{ : # {{ SNIP_SHLIB }}
  # @text_wrap
} # {{ SNIP_SHLIB }}

THE_CMD=text_wrap

shlib_test -t "Doesn't change input on defaults (stdin)" \
    -o 'foo' \
  ${THE_CMD} <<< 'foo'

shlib_test -t "Prepends (stdin)" \
    -o 'foo' -o 'bar' \
  ${THE_CMD} 'foo' <<< 'bar'

shlib_test -t "Wraps (stdin)" \
    -o 'foo' -o 'bar' -o 'baz' \
  ${THE_CMD} 'foo' 'baz' <<< 'bar'

shlib_test -t "Wraps (file)" \
    -o 'foo' -o 'bar' -o 'baz' \
  ${THE_CMD} 'foo' 'baz' <(echo 'bar')

shlib_test -t "Wraps (multi-file)" \
    -o 'foo' -o 'bar' -o 'baz' -o 'qux' \
  ${THE_CMD} 'foo' 'qux' <(echo 'bar') <(echo 'baz')

printf '' \
| shlib_test -t "Prints nothing on blank stdin" \
  ${THE_CMD}

shlib_test -t "Prints nothing on blank file" \
  ${THE_CMD} 'foo' 'bar' <(printf '')

shlib_test -t "Gets stuck on no FILE / TEXT" \
    -E -b fake_cat_stuck -a check_cat_stuck \
  ${THE_CMD}

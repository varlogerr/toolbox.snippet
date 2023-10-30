{ : # {{ SNIP_SHLIB }}
  # @text_append
} # {{ SNIP_SHLIB }}

THE_CMD=text_append

shlib_test -t "Appends (stdin)" \
    -o 'foo' -o 'bar' \
  ${THE_CMD} 'bar' <<< 'foo'

shlib_test -t "Appends (file)" \
    -o 'foo' -o 'bar' \
  ${THE_CMD} 'bar' <(echo 'foo')

shlib_test -t "Appends (multi-file)" \
    -o 'foo' -o 'bar' -o 'baz' \
  ${THE_CMD} 'baz' <(echo 'foo') <(echo 'bar')

printf '' \
| shlib_test -t "Prints nothing on blank stdin" \
  ${THE_CMD}

shlib_test -t "Prints nothing on blank file" \
  ${THE_CMD} 'foo' <(printf '')

shlib_test -t "Gets stuck on no FILE / TEXT" \
    -E -b fake_cat_stuck -a check_cat_stuck \
  ${THE_CMD}

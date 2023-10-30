{ : # {{ SNIP_SHLIB }}
  # @escape_quote_single
} # {{ SNIP_SHLIB }}

THE_CMD=escape_quote_single

shlib_test -t "Escapes (stdin)" \
    -o "foo'\\''bar'\\''" \
  ${THE_CMD} <<< "foo'bar'"

shlib_test -t "Escapes (file)" \
    -o "foo2'\\''bar2'\\''" \
  ${THE_CMD} <(echo "foo2'bar2'")

shlib_test -t "Escapes (multi-file)" \
    -o "foo1'\''bar1'\''" -o "foo2'\''bar2'\''" \
  ${THE_CMD} <(echo "foo1'bar1'") <(echo "foo2'bar2'")

shlib_test -t "Gets stuck on no FILE / TEXT" \
    -E -b fake_cat_stuck -a check_cat_stuck \
  ${THE_CMD}

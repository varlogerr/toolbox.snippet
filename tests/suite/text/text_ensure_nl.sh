{ : # {{ SNIP_SHLIB }}
  # @text_ensure_nl
} # {{ SNIP_SHLIB }}

THE_CMD=text_ensure_nl

real_stdin() {
  declare r; r="$(printf 'foo' | ${THE_CMD}; echo "bar")"
  shlib_test_stdout "${r}"
}

real_file() {
  declare r; r="$(${THE_CMD} <(printf 'foo'); echo "bar")"
  shlib_test_stdout "${r}"
}

real_multifile() {
  declare r; r="$(
    ${THE_CMD} <(printf 'foo') <(echo "bar"); echo 'baz'
  )"
  shlib_test_stdout "${r}"
}

shlib_test -t "Ensures new line (stdin)" \
    -a real_stdin -o 'foo' -o 'bar' \
  ${THE_CMD} <<< 'This one is ignored'

shlib_test -t "Ensures new line (file)" \
    -a real_file -o 'foo' -o 'bar' \
  ${THE_CMD} <(echo 'Ignored too')

shlib_test -t "Ensures new line (multi-file)" \
    -a real_multifile -o 'foobar' -o 'baz' \
  ${THE_CMD} <(echo 'Same')

shlib_test -t "Gets stuck on no FILE / TEXT" \
    -E -b fake_cat_stuck -a check_cat_stuck \
  ${THE_CMD}

{ : # {{ SNIP_SHLIB }}
  # @text_fmt
} # {{ SNIP_SHLIB }}

THE_CMD=text_fmt
FIXTURES_DIR="${SHLIB_TEXT_FIXTURES_DIR}/text_fmt"

shlib_test -t "Formats (stdin)" \
    -o 'foo' -o '  bar' -o 'baz' \
  ${THE_CMD} < "${FIXTURES_DIR}/unformatted.txt"

shlib_test -t "Formats (file)" \
    -o 'foo' -o '  bar' -o 'baz' \
  ${THE_CMD} "${FIXTURES_DIR}/unformatted.txt"

shlib_test -t "Formats (multi-file)" \
    -o 'foo' -o '  bar' -o 'baz' -o '' -o 'foo' -o '  bar' -o 'baz' \
  ${THE_CMD} "${FIXTURES_DIR}/unformatted.txt" "${FIXTURES_DIR}/unformatted.txt"

shlib_test -t "Gets stuck on no FILE / TEXT" \
    -E -b fake_cat_stuck -a check_cat_stuck \
  ${THE_CMD}

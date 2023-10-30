{ : # {{ SNIP_SHLIB }}
  # @text_undecore
} # {{ SNIP_SHLIB }}

THE_CMD=text_undecore
FIXTURES_DIR="${SHLIB_TEXT_FIXTURES_DIR}/text_undecore"

shlib_test -t "Undecores with default symbol (stdin)" \
    -o 'hello' -o '  world' \
  ${THE_CMD} < "${FIXTURES_DIR}/default-symbol.txt"

shlib_test -t "Undecores with default symbol (file)" \
    -o 'hello' -o '  world' \
  ${THE_CMD} "${FIXTURES_DIR}/default-symbol.txt"

shlib_test -t "Undecores (multi-file)" \
    -o 'hello' -o '  world' -o 'hello' -o '  world' \
  ${THE_CMD} "${FIXTURES_DIR}/default-symbol.txt" "${FIXTURES_DIR}/default-symbol.txt"

shlib_test -t "Undecores with custom symbol (--symbol '...')" \
    -o 'hello' -o '  world' \
  ${THE_CMD} --symbol '$' "${FIXTURES_DIR}/custom-symbol.txt"

shlib_test -t "Undecores with custom symbol (--symbol='...')" \
    -o 'hello' -o '  world' \
  ${THE_CMD} --symbol='$' "${FIXTURES_DIR}/custom-symbol.txt"

shlib_test -t "Gets stuck on no FILE / TEXT" \
    -E -b fake_cat_stuck -a check_cat_stuck \
  ${THE_CMD}

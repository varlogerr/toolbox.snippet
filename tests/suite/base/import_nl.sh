{ : # {{ SNIP_SHLIB }}
  # @import_nl
} # {{ SNIP_SHLIB }}

THE_CMD=import_nl

unset_default() { unset -v SHLIB_NL; }
check_default() { [[ "foo${SHLIB_NL}bar" == $'foo\nbar' ]]; shlib_test_rc $?; }

unset_custom() { unset -v FOO_NL; }
check_custom() { [[ "foo${FOO_NL}bar" == $'foo\nbar' ]]; shlib_test_rc $?; }

shlib_test -t "Imports default variable" \
    -b unset_default -a check_default \
  ${THE_CMD}

shlib_test -t "Imports custom variable" \
    -b unset_custom -a check_custom \
  ${THE_CMD} FOO_NL

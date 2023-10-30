fake_cat_stuck() { cat() {
  timeout -- 0.03 /usr/bin/env cat "${@}" || {
    echo "CAT GOT STUCK" >&2
    exit 2
  }
}; }

check_cat_stuck() {
  declare -i init_rc; init_rc=$(shlib_test_rc)
  shlib_test_rc 0

  [[ ${init_rc} -eq 2 ]] \
  && shlib_test_stderr | grep -qFx 'CAT GOT STUCK' \
  && shlib_test_rc "${init_rc}"
}

{ : # {{ SNIP_SHLIB }}
  # @cache_fs
} # {{ SNIP_SHLIB }}

THE_CMD=cache_fs

check_cache() {
  declare key="${1}"; val="${2}"
  declare cache; cache="$(cache_fs "${key}")"

  [[ "${cache}" == "${val}" ]]; shlib_test_rc $?
}

check_cache_content_foo1() {
  check_cache '7386b2c3-5bbe-4e2b-976a-970ee4458612' 'foo1'
}
check_cache_content_foo2() {
  check_cache '7073645a-45a9-4c4a-9997-2c3518ffde88' 'foo2'
}
check_cache_content_foo12() {
  check_cache '7073645a-45a9-4c4a-9997-2c3518ffde88' $'foo1\nfoo2'
}

shlib_test -t "Set / get (stdin)" \
    -o 'foo1' -a check_cache_content_foo1 \
  ${THE_CMD} '7386b2c3-5bbe-4e2b-976a-970ee4458612' - <<< 'foo1'

shlib_test -t "Set / get (file)" \
    -o 'foo2' -a check_cache_content_foo2 \
  ${THE_CMD} '7073645a-45a9-4c4a-9997-2c3518ffde88' <(echo 'foo2')

shlib_test -t "Update / get (multi-file)" \
    -o $'foo1\nfoo2' -a check_cache_content_foo12 \
  ${THE_CMD} '7073645a-45a9-4c4a-9997-2c3518ffde88' <(echo 'foo1') <(echo 'foo2')

shlib_test -t "Gets stuck with key, but without FILE / TEXT" \
    -E -b fake_cat_stuck -a check_cat_stuck \
  ${THE_CMD} '2b36b9bf-83f7-4ba2-b1b8-3393650b964a' -

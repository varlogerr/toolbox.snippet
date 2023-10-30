import_nl() {
  { # META
    meta_info "Import robust new line variable."
    meta_usage "
      # Import SHLIB_NL to the global scope
      {{ CMD }}

      # Trap SHLIB_NL in the my_func scope
      my_func() { declare SHLIB_NL; {{ CMD }}; }

      # Trap to a custom variable
      declare FOO_NL; {{ CMD }} FOO_NL
    "
    meta_more "
      REFERENCES:
        * https://stackoverflow.com/a/64938613
    "
    meta_end
  } # META

  [[ ${#} -gt 0 ]] || { "${FUNCNAME[0]}" SHLIB_NL; return; }

  declare -n _NL_UJgw7xERseSEcVC="${1}"
  _NL_UJgw7xERseSEcVC="$(printf '\nX')"; _NL_UJgw7xERseSEcVC="${_NL_UJgw7xERseSEcVC%X}";
}

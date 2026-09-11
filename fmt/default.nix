# fmt 11.2.0 — CyberEther meson subproject bundle
#
# CyberEther's loader (meson/loaders/fmt/meson.build) calls
# `subproject('fmt', required: true)` directly, so meson needs this source in
# its wrap cache. Contents mirror subprojects/packagecache/ for
# subprojects/fmt.wrap (`source_filename` = fmt-11.2.0.tar.gz,
# `source_hash` = bc23066d...). The `patch_directory = fmt` glue lives in the
# CyberEther repo (subprojects/packagefiles/fmt) and is applied by meson.
{ runCommand, fetchurl }:

let
  src = fetchurl {
    name = "fmt-11.2.0.tar.gz";
    url = "https://github.com/fmtlib/fmt/archive/11.2.0.tar.gz";
    sha256 = "bc23066d87ab3168f27cef3e97d545fa63314f5c79df5ea444d41d56f962c6af";
  };
in
runCommand "fmt-subproject-bundle" { } ''
  mkdir -p $out
  ln -s ${src} $out/fmt-11.2.0.tar.gz
''

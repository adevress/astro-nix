# cpp-httplib 0.40.0 — CyberEther meson subproject bundle
#
# HTTP client used by the feedback / remote features. Wrap:
# subprojects/cpp-httplib.wrap (no wrap patch). CyberEther applies
# `b_lto=false` on its loader (see cyberether/patches/) because Nix binutils
# cannot resolve slim-LTO objects in static archives.
{ runCommand, fetchurl }:

let
  src = fetchurl {
    name = "cpp-httplib-0.40.0.tar.gz";
    url = "https://github.com/yhirose/cpp-httplib/archive/refs/tags/v0.40.0.tar.gz";
    sha256 = "b52ecaebf0f94086c8b3305650412359d920c5267f6d9ce87f883198783af678";
  };
in
runCommand "cpp-httplib-subproject-bundle" { } ''
  mkdir -p $out
  ln -s ${src} $out/cpp-httplib-0.40.0.tar.gz
''

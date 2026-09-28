# cpp-httplib 0.56.0 — CyberEther meson subproject bundle
#
# HTTP client used by the feedback / remote features. Since 0.56.0 the upstream
# tarball ships its own meson.build, so the wrap no longer needs a wrapdb patch
# (see subprojects/cpp-httplib.wrap). CyberEther applies `b_lto=false` on its
# loader (see cyberether/patches/000-cpp-httplib-no-lto.patch) because Nix
# binutils cannot resolve slim-LTO objects in static archives.
{ runCommand, fetchurl }:

let
  src = fetchurl {
    name = "cpp-httplib-0.56.0.tar.gz";
    url = "https://github.com/yhirose/cpp-httplib/archive/refs/tags/v0.56.0.tar.gz";
    sha256 = "41f214d844e3b9117b734a8cc305b6141c5b47d63009681944e03bc31d92b9ca";
  };
in
runCommand "cpp-httplib-subproject-bundle" { } ''
  mkdir -p $out
  ln -s ${src} $out/cpp-httplib-0.56.0.tar.gz
''

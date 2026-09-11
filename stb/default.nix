# stb — CyberEther meson subproject bundle
#
# Header-only image/text rendering helpers (imgui, fonts). Wrap:
# subprojects/stb.wrap is wrap-git pinned at
# f58f558c120e9b32c217290b80bad1a0729fbb2c with `patch_directory = stb`
# (meson build glue in the CyberEther repo). Raw git checkout as an extracted
# source dir (`$out/stb`); meson applies the patches itself.
{ runCommand, fetchgit }:

let
  src = fetchgit {
    url = "https://github.com/nothings/stb.git";
    rev = "f58f558c120e9b32c217290b80bad1a0729fbb2c";
    sha256 = "sha256-FGe6ffCqscwz+kgZcIwWsGaEM/9VnJp+d7bHUTl39DU=";
  };
in
runCommand "stb-subproject-bundle" { } ''
  mkdir -p $out/stb
  cp -rL ${src}/. $out/stb/
''

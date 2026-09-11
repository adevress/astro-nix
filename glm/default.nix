# glm 1.0.0 — CyberEther meson subproject bundle
#
# Math library. Wrap: subprojects/glm.wrap (source + wrapdb patch zip,
# glm_1.0.0-1 which adds the meson build).
{ runCommand, fetchurl }:

let
  src = fetchurl {
    name = "glm-1.0.0.tar.gz";
    url = "https://github.com/g-truc/glm/archive/refs/tags/1.0.0.tar.gz";
    sha256 = "e51f6c89ff33b7cfb19daafb215f293d106cd900f8d681b9b1295312ccadbd23";
  };
  patch = fetchurl {
    name = "glm_1.0.0-1_patch.zip";
    url = "https://wrapdb.mesonbuild.com/v2/glm_1.0.0-1/get_patch";
    sha256 = "fbb97f9cca2bda1f9dea6efddf3742105613b8e68d089b9a01307159bd2f37a1";
  };
in
runCommand "glm-subproject-bundle" { } ''
  mkdir -p $out
  ln -s ${src} $out/glm-1.0.0.tar.gz
  ln -s ${patch} $out/glm_1.0.0-1_patch.zip
''

# robin-map 1.4.0 — CyberEther meson subproject bundle
#
# Hash map used by nanobind (fallback subproject for its robin-map
# dependency). Wrap: subprojects/robin-map.wrap — github archive + wrapdb
# patch zip (robin-map_1.4.0-1).
{ runCommand, fetchurl }:

let
  src = fetchurl {
    name = "robin-map-1.4.0.tar.gz";
    url = "https://github.com/Tessil/robin-map/archive/refs/tags/v1.4.0.tar.gz";
    sha256 = "7930dbf9634acfc02686d87f615c0f4f33135948130b8922331c16d90a03250c";
  };
  patch = fetchurl {
    name = "robin-map_1.4.0-1_patch.zip";
    url = "https://wrapdb.mesonbuild.com/v2/robin-map_1.4.0-1/get_patch";
    sha256 = "feb14b6752b7d439fb2f3ee968e595a9a3de00ef8cb029488af2ceb4f504b95d";
  };
in
runCommand "robin-map-subproject-bundle" { } ''
  mkdir -p $out
  ln -s ${src} $out/robin-map-1.4.0.tar.gz
  ln -s ${patch} $out/robin-map_1.4.0-1_patch.zip
''

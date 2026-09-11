# nlohmann_json 3.12.0 — CyberEther meson subproject bundle
#
# JSON parser. Wrap: subprojects/nlohmann_json.wrap — the release `include.zip`
# (lead_directory_missing = true; meson extracts the include/ tree itself).
{ runCommand, fetchurl }:

let
  src = fetchurl {
    name = "nlohmann_json-3.12.0.zip";
    url = "https://github.com/nlohmann/json/releases/download/v3.12.0/include.zip";
    sha256 = "b8cb0ef2dd7f57f18933997c9934bb1fa962594f701cd5a8d3c2c80541559372";
  };
in
runCommand "nlohmann_json-subproject-bundle" { } ''
  mkdir -p $out
  ln -s ${src} $out/nlohmann_json-3.12.0.zip
''

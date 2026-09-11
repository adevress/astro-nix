# rapidyaml 0.11.1 — CyberEther meson subproject bundle
#
# YAML parser. Wrap: subprojects/rapidyaml.wrap — release asset
# rapidyaml-0.11.1-src.tgz; `patch_directory = rapidyaml` glue lives in the
# CyberEther repo.
{ runCommand, fetchurl }:

let
  src = fetchurl {
    name = "rapidyaml-0.11.1-src.tgz";
    url = "https://github.com/biojppm/rapidyaml/releases/download/v0.11.1/rapidyaml-0.11.1-src.tgz";
    sha256 = "9d9938269adc25e9a9b84650338b87d130cf469d82685fffc028c325279619c1";
  };
in
runCommand "rapidyaml-subproject-bundle" { } ''
  mkdir -p $out
  ln -s ${src} $out/rapidyaml-0.11.1-src.tgz
''

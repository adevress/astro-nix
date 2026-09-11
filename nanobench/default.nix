# nanobench 4.3.11 — CyberEther meson subproject bundle
#
# Benchmarking utilities (src/benchmark.cc). Wrap: subprojects/nanobench.wrap —
# github archive; `patch_directory = nanobench` glue lives in the repo.
{ runCommand, fetchurl }:

let
  src = fetchurl {
    name = "nanobench-4.3.11.tar.gz";
    url = "https://github.com/martinus/nanobench/archive/refs/tags/v4.3.11.tar.gz";
    sha256 = "53a5a913fa695c23546661bf2cd22b299e10a3e994d9ed97daf89b5cada0da70";
  };
in
runCommand "nanobench-subproject-bundle" { } ''
  mkdir -p $out
  ln -s ${src} $out/nanobench-4.3.11.tar.gz
''

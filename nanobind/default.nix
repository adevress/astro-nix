# nanobind 2.12.0 — CyberEther meson subproject bundle
#
# C++ Python binding framework used by the Superluminal bindings
# (python/superluminal/meson.build). Wrap: subprojects/nanobind.wrap — github
# archive + wrapdb patch zip (nanobind_2.12.0-1).
#
# Deviation from the pinned archive: the extracted source directory is shipped
# in the meson wrap cache (instead of only the tarball) so that
# `src/version.py` — which meson executes directly via its
# `#!/usr/bin/env python3` shebang — works inside the Nix build sandbox (no
# /usr/bin/env there). meson picks the cached directory, applies the wrapdb
# patch zip on top, and the wrap hash check still passes (it only hashes
# downloaded files, not copied cached directories).
{
  runCommand,
  fetchurl,
  python3,
}:

let
  src = fetchurl {
    name = "nanobind-2.12.0.tar.gz";
    url = "https://github.com/wjakob/nanobind/archive/refs/tags/v2.12.0.tar.gz";
    sha256 = "01f1f0cd0398743c18f33d07ae36ad410bd7f4a1e90683b508504de897d6e629";
  };
  patch = fetchurl {
    name = "nanobind_2.12.0-1_patch.zip";
    url = "https://wrapdb.mesonbuild.com/v2/nanobind_2.12.0-1/get_patch";
    sha256 = "4b8158bdb359218bcfb7a5b4459fbfa5919171d9ea2400de3a84cf9ab7c7308b";
  };
in
runCommand "nanobind-subproject-bundle"
  {
    nativeBuildInputs = [ python3 ];
  }
  ''
    mkdir -p $out
    cp ${src} "$out/nanobind-2.12.0.tar.gz"
    cp ${patch} "$out/nanobind_2.12.0-1_patch.zip"
    mkdir -p work
    tar xzf ${src} -C work
    # Sandbox-safe shebang (meson runs this script directly).
    sed -i "1s|.*|#!${python3}/bin/python3|" work/nanobind-2.12.0/src/version.py
    chmod +x work/nanobind-2.12.0/src/version.py
    cp -r work/nanobind-2.12.0 "$out/"
  ''

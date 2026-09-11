# libmodes — CyberEther meson subproject bundle
#
# ADS-B Mode-S decoder block. Wrap: subprojects/libmodes.wrap is wrap-git
# pinned at e82c6faedd21ced7fd1c2808c0d9e9ffbb8c0ed6 with
# `patch_directory = libmodes` + `diff_files = libmodes/mode-s-timeh.diff`
# (both in the CyberEther repo). This package ships the raw git checkout as an
# extracted source dir (`$out/libmodes`); meson's wrap resolver copies it from
# the cache dir and applies the patches itself.
{ runCommand, fetchgit }:

let
  src = fetchgit {
    url = "https://github.com/watson/libmodes.git";
    rev = "e82c6faedd21ced7fd1c2808c0d9e9ffbb8c0ed6";
    sha256 = "sha256-brU6IYHcCJbArYf4DMyj3DfKp2unsjZq+IaM5M1pK1I=";
  };
in
runCommand "libmodes-subproject-bundle" { } ''
  mkdir -p $out/libmodes
  cp -rL ${src}/. $out/libmodes/
''

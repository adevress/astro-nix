# qrencode 4.1.1 — CyberEther meson subproject bundle
#
# QR codes (remote pairing UI). Wrap: subprojects/qrencode.wrap — github
# archive + wrapdb patch zip (qrencode_4.1.1-3). Built statically.
{ runCommand, fetchurl }:

let
  src = fetchurl {
    name = "libqrencode-4.1.1.tar.gz";
    url = "https://github.com/fukuchi/libqrencode/archive/refs/tags/v4.1.1.tar.gz";
    sha256 = "5385bc1b8c2f20f3b91d258bf8ccc8cf62023935df2d2676b5b67049f31a049c";
  };
  patch = fetchurl {
    name = "qrencode_4.1.1-3_patch.zip";
    url = "https://wrapdb.mesonbuild.com/v2/qrencode_4.1.1-3/get_patch";
    sha256 = "2c95bbbe32122b7dacd325c878f21039e1e77c3e12e8f2f74c4d7f07cc99de46";
  };
in
runCommand "qrencode-subproject-bundle" { } ''
  mkdir -p $out
  ln -s ${src} $out/libqrencode-4.1.1.tar.gz
  ln -s ${patch} $out/qrencode_4.1.1-3_patch.zip
''

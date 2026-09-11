# glfw 3.4 — CyberEther meson subproject bundle
#
# Vulkan window manager (X11 + Wayland). Wrap: subprojects/glfw.wrap
# (source + wrapdb patch zip, glfw_3.4-2).
{ runCommand, fetchurl }:

let
  src = fetchurl {
    name = "glfw-3.4.tar.gz";
    url = "https://github.com/glfw/glfw/archive/refs/tags/3.4.tar.gz";
    sha256 = "c038d34200234d071fae9345bc455e4a8f2f544ab60150765d7704e08f3dac01";
  };
  patch = fetchurl {
    name = "glfw_3.4-2_patch.zip";
    url = "https://wrapdb.mesonbuild.com/v2/glfw_3.4-2/get_patch";
    sha256 = "c722d2983acaea2b2ed68570cc7958a10485d8362547cff67713ed4859aa2bc8";
  };
in
runCommand "glfw-subproject-bundle" { } ''
  mkdir -p $out
  ln -s ${src} $out/glfw-3.4.tar.gz
  ln -s ${patch} $out/glfw_3.4-2_patch.zip
''

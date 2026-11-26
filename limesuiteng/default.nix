# LimeSuiteNG 25.1.0 — next-generation LimeSDR driver and library.
#
# This is the version required by CyberEther 2.x (`limesuiteng` API, not the
# legacy `limesuite` API that Nixpkgs currently ships).
#
# Only the core library and its development files are built: the Linux PCIe
# kernel module, CLI, GUI, SoapySDR plugin and Doxygen docs are disabled.
# USB support is provided by the Nixpkgs libusb-1.0.
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  ninja,
  pkg-config,
  libusb1,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "limesuiteng";
  version = "25.1.0";

  src = fetchFromGitHub {
    owner = "myriadrf";
    repo = "LimeSuiteNG";
    rev = "v${finalAttrs.version}";
    hash = "sha256-cBKaFzwO8zxGLNnqHa6i+vsxVV5GBk/QMDahfujjKuY=";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  buildInputs = [
    libusb1
  ];

  cmakeFlags = [
    "-DBUILD_DRIVERS=OFF"
    "-DBUILD_CLI=OFF"
    "-DBUILD_GUI=OFF"
    "-DBUILD_PLUGINS=OFF"
    "-DBUILD_DOCS=OFF"
    "-DBUILD_EXAMPLES=OFF"
    "-DINSTALL_UDEV_RULES=OFF"
    "-DENABLE_UNIT_TESTS=OFF"
    "-DINSTALL_DEVELOPMENT=ON"
    "-DBUILD_SHARED_LIBS=ON"
    # Bundled `rang` still declares cmake_minimum_required(<3.5).
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "LimeSuiteNG - driver and C++ API for LimeSDR devices";
    homepage = "https://github.com/myriadrf/LimeSuiteNG";
    license = licenses.asl20;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
})

{
  lib,
  stdenv,
  fetchgit,
  cmake,
  pkg-config,
  boost,
  cfitsio,
  fftw,
  gsl,
  hdf5,
  lua54Packages,
  libpng,
  python3Packages,
  libsigcxx,
  aocommon,
}:

stdenv.mkDerivation rec {
  name = "aoflagger";
  version = "dev";

  src = fetchgit {
    url = "https://gitlab.com/aroffringa/aoflagger.git";
    rev = "c868186168392666a097bdf67a97757a947d7c54"; # main the 20/04/2026
    sha256 = "sha256-TXAvr9YXfDa56LYnk2n3zYwzFdAYw1IPWWLZ/etK8c0=";
    fetchSubmodules = false; # disable submodules
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    boost
    cfitsio
    fftw
    gsl
    hdf5
    lua54Packages.lua
    libpng
    python3Packages.python
    python3Packages.pybind11
    libsigcxx
    aocommon
  ];

  # Remove aocommon submodule from source since we're providing it separately
  postPatch = ''
    rm -rf external/aocommon

    # Create symlink to our packaged version
    mkdir -p external
    ln -s ${aocommon} external/aocommon
  '';

  cmakeFlags = [
    "-DENABLE_GUI=OFF" # Disable GUI to avoid GTKMM dependency
    "-DGIT_SUBMODULE=OFF"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=TRUE"
    "-DBUILD_TESTING=ON"
    "-DPORTABLE=ON"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "AOFlagger - Radio Frequency Interference detection and removal tool";
    homepage = "https://gitlab.com/aroffringa/aoflagger";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}

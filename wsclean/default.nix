{ stdenv, fetchgit, cmake, python3Packages, aocommon, boost, fftw, fftwFloat, gsl, cfitsio, hdf5, git, radler, schaapcommon, idg ? null, ska-sdp-func ? null, lib }:

stdenv.mkDerivation rec {
  name = "wsclean";
  version = "3.7-dev"; 

  src = fetchgit {
    url = "https://gitlab.com/aroffringa/wsclean.git";
    rev = "2b1a430ca1666677f9bb6f4e997134a75465e852";
    sha256 = "sha256-CbSbnCswlZt1YXFd0kfIrZ63jEBuEupYDH0s5rgdgHg";
    fetchSubmodules = false;
  };

  nativeBuildInputs = [ cmake git ];
  buildInputs = [
    python3Packages.python
    python3Packages.pybind11
    boost
    fftw
    fftwFloat
    gsl
    cfitsio
    hdf5
    radler
    aocommon
    schaapcommon
    ska-sdp-func
    idg
  ];

  patches = [ ./0001-Add-a-cmake-option-to-allow-build-from-external-dire.patch ];

  # Remove submodules from source since we're providing them separately
  postPatch = ''
    rm -rf external/aocommon
    rm -rf external/radler
    rm -rf external/schaapcommon
    
    # Create symlinks to our packaged versions
    mkdir -p external
    ln -s ${aocommon} external/aocommon
    ln -s ${radler} external/radler
    ln -s ${schaapcommon} external/schaapcommon
  '';

  cmakeFlags = [
    "-DGIT_SUBMODULE=OFF"
    "-DPORTABLE=ON"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=ON"
    "-DWSCLEAN_DEPENDENCIES_VENDORING=OFF"
    "-DAOCOMMON_INCLUDE_DIR=${aocommon}/include/"
    "-DSCHAAPCOMMON_SOURCE_DIR=${schaapcommon}"
    "-DBUILD_PACKAGES=OFF"
  ] ++ lib.optionals (ska-sdp-func != null) [ "-DENABLE_WTOWERS=ON" "-DSKA_SDP_FUNC_INCLUDE_DIR=${ska-sdp-func}/include" ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "WSClean - A fast widefield interferometric imager";
    homepage = "https://gitlab.com/aroffringa/wsclean";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}

{ stdenv, fetchgit, cmake, python3Packages, boost, fftw, fftwFloat, gsl, cfitsio, hdf5, openmpi, casacore, git, aocommon, schaapcommon, lib, wget }:

stdenv.mkDerivation rec {
  name = "everybeam";
  version = "0.8.2";

  src = fetchgit {
    url = "https://gitlab.com/ska-telescope/sdp/ska-sdp-func-everybeam.git";
    rev = "v${version}";
    sha256 = "sha256-0000000000000000000000000000000000000000000000000000000000000000"; # TODO: Update with actual sha256
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ cmake git python3Packages.pybind11 wget ];
  buildInputs = [
    python3Packages.python
    boost
    fftw
    fftwFloat
    gsl
    cfitsio
    hdf5
    openmpi
    casacore
    aocommon
    schaapcommon
  ];

  # Remove submodules from source since we're providing them separately
  postPatch = ''
    rm -rf external/aocommon
    rm -rf external/schaapcommon
    
    # Create symlinks to our packaged versions
    mkdir -p external
    ln -s ${aocommon} external/aocommon
    ln -s ${schaapcommon} external/schaapcommon
  '';

  cmakeFlags = [
    "-DBUILD_WITH_PYTHON=OFF"
    "-DBUILD_TESTING=OFF"
    "-DBUILD_APT_PACKAGES=OFF"
    "-DPORTABLE=OFF"
    "-DDOWNLOAD_LOBES=OFF"
    "-DDOWNLOAD_LWA=OFF"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "EveryBeam - A library that provides the antenna response pattern for several instruments";
    homepage = "https://gitlab.com/ska-telescope/sdp/ska-sdp-func-everybeam";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}
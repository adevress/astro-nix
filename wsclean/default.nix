{ stdenv, fetchgit, cmake, python3Packages, boost, fftw, gsl, cfitsio, hdf5, openmpi, casacore, lapack, git, aocommon, radler, schaapcommon, wcstools, lib }:

stdenv.mkDerivation rec {
  name = "wsclean";
  version = "3.2.0"; # TODO: update with correct version

  src = fetchgit {
    url = "https://gitlab.com/aroffringa/wsclean.git";
    rev = "8a464c5441c4121bf578adc21349ed990970b587";
    sha256 = "0000000000000000000000000000000000000000000000000000"; # TODO: update with correct hash
  };

  nativeBuildInputs = [ cmake git ];
  buildInputs = [
    python3Packages.python
    python3Packages.pybind11
    boost
    fftw
    gsl
    cfitsio
    hdf5
    openmpi
    casacore
    lapack
    aocommon
    radler
    schaapcommon
  ];

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
    "-DPORTABLE=OFF"
    "-DBUILD_PACKAGES=OFF"
    "-DENABLE_WTOWERS=OFF"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "WSClean - A fast widefield interferometric imager";
    homepage = "https://gitlab.com/aroffringa/wsclean";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}
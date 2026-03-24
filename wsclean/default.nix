{ stdenv, fetchgit, cmake, python3Packages, aocommon, boost, fftw, fftwFloat, gsl, cfitsio, hdf5, git, radler, schaapcommon, lib }:

stdenv.mkDerivation rec {
  name = "wsclean";
  version = "3.7"; 

  src = fetchgit {
    url = "https://gitlab.com/aroffringa/wsclean.git";
    rev = "v${version}";
    sha256 = "sha256-zRXSoK+cFIBVIcgdvJTD9kmxfnuLoYXZRZQFqUabXpk=";
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
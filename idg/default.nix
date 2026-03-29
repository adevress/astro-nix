{ stdenv, fetchgit, cmake, ninja, pkg-config, aocommon, schaapcommon, xtensor, boost, fftw, fftwFloat, gsl, cfitsio, hdf5, hdf5-cpp, python3Packages, lib }:

stdenv.mkDerivation rec {
  name = "idg";
  version = "1.2.0";

  src = fetchgit {
    url = "https://git.astron.nl/RD/idg.git";
    rev = "216e744320b7852f58a632fa03c29588f42acb86";
    sha256 = "sha256-3q6DsxT7g2MEZW3AgXFJGsy5c7xh4np3K7JzR0g6Naw=";
    fetchSubmodules = false;
  };

  nativeBuildInputs = [ cmake ninja pkg-config ];
  buildInputs = [
    aocommon
    schaapcommon
    xtensor
    boost
    fftw
    fftwFloat
    gsl
    cfitsio
    hdf5
    hdf5-cpp
    python3Packages.python
    python3Packages.pybind11
  ];

  patches = [ ./001-xtensor-path-update.patch ];

  # Remove submodules from source since we're providing them separately
  postPatch = ''
    rm -rf external/aocommon
    rm -rf external/pybind11
    rm -rf external/schaap-packaging
    
    # Create symlinks to our packaged versions
    mkdir -p external
    ln -s ${aocommon} external/aocommon
    ln -s ${schaapcommon} external/schaap-packaging
  '';

  cmakeFlags = [
    "-DFETCHCONTENT_FULLY_DISCONNECTED=TRUE"
    "-DCOMPILE_AS_EXTERNAL_PROJECT=ON"
    "-DPORTABLE=ON"
    "-DBUILD_WITH_DEMOS=OFF"
    "-DBUILD_WITH_MPI=OFF"
    "-DBUILD_PACKAGES=OFF"
    "-DBUILD_TESTING=OFF"
    "-DGIT_SUBMODULE=OFF"
    "-DAOCOMMON_INCLUDE_DIR=${aocommon}/include/"
    "-DSCHAAPCOMMON_SOURCE_DIR=${schaapcommon}/"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "IDG - Image Domain Gridder for radio astronomy";
    homepage = "https://git.astron.nl/RD/idg";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}

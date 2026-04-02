{
  stdenv,
  fetchgit,
  cmake,
  python3Packages,
  boost,
  fftw,
  fftwFloat,
  gsl,
  cfitsio,
  hdf5,
  hdf5-cpp,
  git,
  aocommon,
  xtensor-blas,
  schaapcommon,
  ska-sdp-func,
  lib,
  wget,
}:

stdenv.mkDerivation rec {
  name = "everybeam";
  version = "0.8.2";

  src = fetchgit {
    url = "https://gitlab.com/ska-telescope/sdp/ska-sdp-func-everybeam.git";
    rev = "v${version}";
    sha256 = "sha256-1oVfR3X9AaqF74urjZXD8w6l5/GfIwZnTl59WeJZ1wc=";
    fetchSubmodules = false;
  };

  nativeBuildInputs = [
    cmake
    git
    python3Packages.pybind11
    wget
  ];
  buildInputs = [
    python3Packages.python
    boost
    fftw
    fftwFloat
    gsl
    cfitsio
    hdf5
    hdf5-cpp
    aocommon
    xtensor-blas
    schaapcommon
    ska-sdp-func
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
    "-DEVERYBEAM_DEPENDENCIES_VENDORING=OFF"
    "-DGIT_SUBMODULE=OFF"
    "-DCOMPILE_AS_EXTERNAL_PROJECT=ON" # required for schaapcommon
    "-DAOCOMMON_INCLUDE_DIR=${aocommon}/include/" # required for schaapcommon
    "-DFETCHCONTENT_FULLY_DISCONNECTED=TRUE"
    "-DBUILD_WITH_PYTHON=OFF"
    "-DBUILD_TESTING=ON"
    "-DBUILD_APT_PACKAGES=OFF"
    "-DPORTABLE=ON"
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

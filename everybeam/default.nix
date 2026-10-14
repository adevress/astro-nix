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
  schaapcommon,
  ska-sdp-func,
  eigen,
  xtensor,
  xtl,
  xtensor-blas,
  xtensor-fftw,
  lib,
  wget,
}:

stdenv.mkDerivation rec {
  name = "everybeam";
  version = "0.8.5";

  src = fetchgit {
    url = "https://gitlab.com/ska-telescope/sdp/ska-sdp-func-everybeam.git";
    rev = "v${version}";
    sha256 = "sha256-db6FPxdSUwltKehH5rYogTywEFNIA5tpVsVidQnjL5U=";
    fetchSubmodules = false;
  };

  # Use the shared, separately packaged ska-sdp-func instead of the private
  # revision EveryBeam would otherwise vendor (and bundle as an OBJECT
  # library) through FetchContent.  Bundling it duplicates symbols when
  # another package (e.g. OSKAR or WSClean) links the shared ska-sdp-func too.
  # The packaged revision df10e08 is newer than the one EveryBeam pins and
  # exposes the same headers/ABI.
  #
  # EveryBeam 0.8.5 dropped Casacore's 'fits' component because the aocommon
  # revision it bundles no longer calls casacore::FITSDateUtil.  The separately
  # packaged aocommon still uses it, so keep linking casacore_fits.
  patches = [
    ./0001-casacore-fits-component.patch
    ./0002-use-system-ska-sdp-func.patch
  ];

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
    eigen
    aocommon
    ska-sdp-func
    xtensor
    xtl
    xtensor-blas
    xtensor-fftw
    schaapcommon
  ];

  # EveryBeam normally downloads its git submodules and its CMake
  # dependencies (xtensor, ...) from the network.  Use the packaged /
  # source-pinned copies instead so the build stays hermetic.
  postPatch = ''
    rm -rf external/aocommon external/schaapcommon external/eigen

    mkdir -p external
    ln -s ${aocommon} external/aocommon
    ln -s ${schaapcommon} external/schaapcommon
    # EveryBeam puts external/eigen on the include path and includes
    # <Eigen/Core>; nixpkgs' eigen ships its headers under include/eigen3.
    ln -s ${eigen}/include/eigen3 external/eigen
  '';

  cmakeFlags = [
    # Provide the remaining FetchContent dependencies from local trees.
    # ska-sdp-func is found with find_package() instead (see the patch).
    "-DFETCHCONTENT_SOURCE_DIR_XTL=${xtl}"
    "-DFETCHCONTENT_SOURCE_DIR_XTENSOR=${xtensor}"
    "-DFETCHCONTENT_SOURCE_DIR_XTENSOR-BLAS=${xtensor-blas}"
    "-DFETCHCONTENT_SOURCE_DIR_XTENSOR-FFTW=${xtensor-fftw}"
    "-DGIT_SUBMODULE=OFF"
    "-DAOCOMMON_INCLUDE_DIR=${aocommon}/include/" # required for schaapcommon
    "-DBUILD_WITH_PYTHON=OFF"
    # Tests pull multi-GB LOBES/LWA coefficient data over the network at build
    # time, which is impossible in the sandbox.
    "-DBUILD_TESTING=OFF"
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

# DP3 — streaming processing pipeline for radio interferometric data.
#
# DP3 is a C++/Python project: upstream ships a ``setup.py`` that drives a CMake
# build and installs the ``dp3`` Python package (pybind11 bindings + a pure
# Python layer), next to the ``DP3`` command line tool and ``libDP3.so``.
# The setup.py path relies on auditwheel to bundle ``libDP3.so`` into the wheel,
# which is not available in a Nix build.  We therefore install through CMake
# directly (``format = "other"``) so that both the shared library and the Python
# package end up in ``$out`` with a correct install RPATH.
{
  lib,
  buildPythonPackage,
  fetchgit,
  # Pinned DP3 test data (MWA MeasurementSet, casacore measures); see
  # ../test_data/default.nix.
  mwaTestMs,
  casarc,
  cmake,
  ninja,
  pkg-config,
  python,
  numpy,
  pytest,
  h5py,
  astropy,
  python-casacore,
  casacore,
  cfitsio,
  hdf5,
  hdf5-cpp,
  gsl,
  boost,
  openblas,
  aoflagger,
  everybeam,
  idg,
  dysco,
  xtensor,
  xtl,
  xsimd,
  xtensor-blas,
}:
buildPythonPackage rec {
  pname = "dp3";
  version = "6.6.0";
  format = "other";

  # Use the exact upstream tag, with all git submodules (aocommon, schaapcommon,
  # pybind11, predict, schaap-packaging) checked out at the revisions DP3 pins.
  # DP3's CMake hard-codes these in-tree submodules and uses them both for the
  # build and as the source of its CMake helper modules.
  src = fetchgit {
    url = "https://github.com/lofar-astron/DP3.git";
    rev = "v${version}";
    hash = "sha256-/+q3kNGR266frb1oXH8nIAPiQV4H7Xx1vQufHxPBYY4=";
    fetchSubmodules = true;
  };

  # DP3 6.6 is written against the xsimd >= 14 make_batch_constant<T, G> API,
  # while the pinned nixpkgs ships xsimd 13.2.0, whose generator API takes an
  # explicit architecture: make_batch_constant<T, A, G>.
  patches = [ ./0001-xsimd-13-compat.patch ];

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    python
    # pytest is needed at configure time: DP3 probes the DDECal test functions
    # with `pytest --collect-only` to create one ctest entry per subtest.
    pytest
  ];

  buildInputs = [
    casacore
    cfitsio
    hdf5
    hdf5-cpp
    gsl
    boost
    openblas
    aoflagger
    everybeam
    idg
  ];

  # The dp3 Python layer imports numpy.
  dependencies = [ numpy ];

  # Python modules imported by the integration tests.
  nativeCheckInputs = [
    pytest
    h5py
    astropy
    python-casacore
    # Provides the standalone "Dysco" casacore storage manager (loaded via
    # CASACORE_LDPATH below).
    dysco
  ];

  # CMakeLists.txt picks up the XTensor stack through aocommon's
  # FetchXTensor.cmake, which would otherwise clone GitHub at configure time.
  # Disconnect FetchContent and hand it the upstream nixpkgs sources instead.
  # The MWA test MeasurementSet is normally downloaded through ExternalProject;
  # point it at the prefetched tarball (the SHA256 in CMakeLists.txt still
  # matches).
  cmakeFlags = [
    "-DPORTABLE=ON"
    "-DBUILD_TESTING=ON"
    "-DGIT_SUBMODULE=OFF"
    "-DCHECK_BLAS=OFF"
    "-DFETCHCONTENT_FULLY_DISCONNECTED=TRUE"
    "-DFETCHCONTENT_SOURCE_DIR_XTL=${xtl}"
    "-DFETCHCONTENT_SOURCE_DIR_XSIMD=${xsimd}"
    "-DFETCHCONTENT_SOURCE_DIR_XTENSOR=${xtensor}"
    "-DFETCHCONTENT_SOURCE_DIR_XTENSOR-BLAS=${xtensor-blas}"
    "-DPython3_EXECUTABLE=${python.interpreter}"
    "-DBLAS_LIBRARIES=${openblas}/lib/libopenblas.so"
    "-DLAPACK_LIBRARIES=${openblas}/lib/libopenblas.so"
    "-DCASACORE_ROOT_DIR=${casacore}"
    "-DCFITSIO_ROOT_DIR=${cfitsio}"
    "-DGSL_ROOT_DIR=${gsl}"
    "-DBOOST_ROOT=${boost}"
    "-DAOFlagger_DIR=${aoflagger}/share/aoflagger/cmake"
    "-DEveryBeam_DIR=${everybeam}/lib/cmake/EveryBeam"
    "-DIDGAPI_DIR=${idg}/share/idgapi/cmake"
  ];

  postPatch = ''
    # Use the prefetched MWA test MeasurementSet instead of downloading it.
    substituteInPlace CMakeLists.txt \
      --replace-fail \
        "https://support.astron.nl/software/ci_data/EveryBeam/MWA-single-timeslot.tar.bz2" \
        "file://${mwaTestMs}"
  '';

  # DP3 is a large C++20 translation unit set; each object can use several GB.
  enableParallelBuilding = true;

  pythonImportsCheck = [ "dp3" ];

  # ctest drives both the C++ unit tests and the pytest-based unit/integration
  # tests.  CASARCFILES points casacore at the pinned measures data.  casacore's
  # storage-manager / derived-column plugins are dlopen()ed by name, so they
  # must be reachable through CASACORE_LDPATH instead of the normal RPATH
  # (this also provides the standalone Dysco storage manager for tMsOut).
  #
  # The six Sisco-compression tests are deselected: astro-nix builds casacore
  # with -DBUILD_SISCO=NO, and there is no standalone Sisco storage manager.
  doCheck = true;

  checkPhase = ''
    runHook preInstallCheck
    export CASARCFILES=${casarc}
    export CASACORE_LDPATH=${casacore}/lib:${dysco}/lib
    export PYTEST_ADDOPTS='-k "not sisco"'
    ctest --output-on-failure --no-tests=error -j''${NIX_BUILD_CORES:-1}
    runHook postInstallCheck
  '';

  # setup.py declares the ``DP3.py`` console script, which the CMake install
  # path does not create.  The wrapPython fixup phase adds the PYTHONPATH.
  postInstall = ''
    cat > $out/bin/DP3.py <<EOF
    #!${python.interpreter}
    from dp3 import entrypoint

    entrypoint()
    EOF
    chmod +x $out/bin/DP3.py
  '';

  meta = with lib; {
    description = "DP3: streaming processing pipeline for radio interferometric data";
    homepage = "https://github.com/lofar-astron/DP3";
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}

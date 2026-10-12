# python-casacore 3.8.1 — Python bindings for CASACORE.
# Required by DDFacet, meqtrees-cattery, and ddf-pipeline.
# Uses the astro-nix casacore package.
{
  lib,
  buildPythonPackage,
  fetchurl,
  numpy,
  cmake,
  ninja,
  scikit-build-core,
  setuptools-scm,
  casacore,
  boost,
  wcslib,
  cfitsio,
  readline,
  openblas,
}:

buildPythonPackage rec {
  pname = "python-casacore";
  version = "3.8.1";
  pyproject = true;

  src = fetchurl {
    name = "python_casacore-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/66/61/96bbc8e1c9751bc83a70a9e94154b9bff3633a56584c00c374dfb1591df1/python_casacore-${version}.tar.gz";
    sha256 = "sha256-dXdjy/W8uOmLaAkwjeEHvLm0GYJ3mxfxY+8gyg7BgyI=";
  };

  build-system = [
    scikit-build-core
    setuptools-scm
  ];

  nativeBuildInputs = [
    cmake
    ninja
  ];

  buildInputs = [
    casacore
    boost
    wcslib
    cfitsio
    readline
    openblas
  ];

  dependencies = [ numpy ];

  cmakeFlags = [
    "-DCASACORE_ROOT_DIR=${casacore}"
    "-DBoost_ROOT=${boost.dev}"
    "-DWcsLib_ROOT=${wcslib}"
    "-DCFITSIO_ROOT=${cfitsio.dev}"
    "-DBLAS_LIBRARIES=${openblas}/lib/libopenblas.so"
    "-DLAPACK_LIBRARIES=${openblas}/lib/libopenblas.so"
  ];

  # scikit-build-core + nixpkgs cmake builder both default to a `build/` dir
  dontUseCmakeBuildDir = true;

  pythonImportsCheck = [ "casacore" ];

  meta = with lib; {
    homepage = "https://github.com/casacore/python-casacore";
    description = "Python bindings for CASACORE, the radio astronomy library";
    license = licenses.lgpl3;
    maintainers = with maintainers; [ ];
  };
}

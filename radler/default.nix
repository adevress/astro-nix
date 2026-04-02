{
  stdenv,
  fetchgit,
  cfitsio,
  cmake,
  ninja,
  aocommon,
  schaapcommon,
  casacore,
  hdf5,
  boost,
  fftw,
  fftwFloat,
  gsl,
  python3Packages,
  doxygen ? null,
  pythonBuild ? false,
  lib,
}:

let
  builder = if pythonBuild then python3Packages.buildPythonPackage else stdenv.mkDerivation;

in
builder rec {
  name = "radler${if pythonBuild then "-python" else ""}";
  version = "1.0.0";

  src = fetchgit {
    url = "https://git.astron.nl/RD/radler.git";
    rev = "v${version}";
    sha256 = "sha256-CsUoLSQ3GN4JJuqHGnLrkKVy3ReOukDVQ03bOYWK5Ag"; # TODO: update with correct hash
    fetchSubmodules = false;
  };

  patches = [
    ./001-pybind-version-fix.patch
    ./radler-set-cpu-flag.patch
  ];

  nativeBuildInputs = [
    cmake
    ninja
  ];
  buildInputs = [
    schaapcommon
    casacore
    cfitsio
    boost
    hdf5
    fftw
    fftwFloat
    gsl
    python3Packages.python
    python3Packages.pybind11
  ]
  ++ (if doxygen != null then [ doxygen ] else [ ]);

  dependencies = (lib.optionals) (pythonBuild) [
    python3Packages.numpy
    python3Packages.astropy
  ];

  build-system = lib.optionals (pythonBuild) [ python3Packages.scikit-build-core ];

  dontUseCmakeConfigure = pythonBuild;

  cmakeFlags = [
    "-DFETCHCONTENT_FULLY_DISCONNECTED=TRUE"
    "-DCOMPILE_AS_EXTERNAL_PROJECT=ON"
    "-DPORTABLE=ON"
    "-DBUILD_PYTHON_BINDINGS=${if pythonBuild then "ON" else "OFF"}"
    "-DBUILD_DOCUMENTATION=OFF"
    "-DBUILD_DOCSTRINGS=OFF"
    "-DAOCOMMON_INCLUDE_DIR=${aocommon}/include/"
    "-DSCHAAPCOMMON_SOURCE_DIR=${schaapcommon}/"
    "-DCASACORE_ROOT_DIR=${casacore}/"
  ];

  pyproject = pythonBuild;

  meta = with lib; {
    description = "Radler - Radio Astronomy Data Library for Efficient Reduction";
    homepage = "https://git.astron.nl/RD/radler";
    license = licenses.lgpl3;
    maintainers = with maintainers; [ ];
  };
}

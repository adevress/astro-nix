{
  stdenv,
  fetchFromGitHub,
  cmake,
  gfortran,
  python3Packages,
  boost,
  hdf5,
  cfitsio,
  fftw,
  fftwFloat,
  openblas,
  readline,
  flex,
  bison,
  wcslib,
  zlib,
  gsl,
  pkg-config,
  lib,
}:

stdenv.mkDerivation rec {
  name = "casacore";
  version = "3.8.2";

  src = fetchFromGitHub {
    owner = "casacore";
    repo = "casacore";
    rev = "v${version}";
    sha256 = "sha256-c8bRAx08YIERkAyXDWRV2v6ZjKtT0BWz8+W1Y1VmvBM=";
  };

  nativeBuildInputs = [
    cmake
    python3Packages.python
    gfortran
    flex
    bison
    pkg-config
  ];
  buildInputs = [
    python3Packages.numpy
    python3Packages.boost
    boost
    hdf5
    cfitsio
    fftw
    fftwFloat
    wcslib
    openblas
    readline
    gsl
    zlib
  ];

  enableParallelBuilding = true;

  cmakeFlags = [
    "-DUSE_HDF5=YES"
    "-DBUILD_PYTHON=NO"
    "-DBUILD_PYTHON3=YES"
    "-DBUILD_DEPRECATED=NO"
    "-DBUILD_FFTPACK_DEPRECATED=NO"
    "-DBUILD_DYSCO=NO"
    "-DBUILD_SISCO=NO"
    "-DBUILD_TESTING=OFF"
    "-DBUILD_DOCUMENTATION=OFF"
  ];

  meta = with lib; {
    description = "Casacore - Astronomy data processing library";
    homepage = "https://github.com/casacore/casacore";
    license = licenses.lgpl21;
    maintainers = with maintainers; [ ];
  };
}

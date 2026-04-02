{
  stdenv,
  fetchgit,
  pkg-config,
  cmake,
  fftw,
  fftwFloat,
  fftwLongDouble,
  gtest,
  xtensor,
  lib,
}:

stdenv.mkDerivation rec {
  name = "xtensor-fftw";
  version = "0.2.6-dev";

  src = fetchgit {
    url = "https://github.com/xtensor-stack/xtensor-fftw.git";
    rev = "127aae73d9def7d421045d1fe5cf6b9c73da3542";
    sha256 = "sha256-OWzJBqtoT3DykrkKfv8MS79fma+PNnLnBV1fXARrKho=";
  };

  nativeBuildInputs = [
    cmake
    pkg-config
  ];
  buildInputs = [
    gtest
    fftw
    fftwFloat
    fftwLongDouble
  ];
  propagatedBuildInputs = [ xtensor ];

  patchPhase = ''
    sed -i 's/@CMAKE_INSTALL_LIBDIR@/lib/g' xtensor-fftw.pc.in 
  '';

  cmakeFlags = [
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    "-DBUILD_TESTS=ON"
    "-DBUILD_BENCHMARK=OFF"
    "-DFIX_RPATH=ON"
    "-DFFTW_USE_FLOAT=ON"
  ];

  meta = with lib; {
    description = "FFTW bindings for the xtensor C++ multi-dimensional array library";
    homepage = "https://github.com/xtensor-stack/xtensor-fftw";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ];
  };
}

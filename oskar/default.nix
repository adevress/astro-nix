{
  stdenv,
  fetchFromGitHub,
  cmake,
  hdf5,
  ska-sdp-func,
  lib,
  python3Packages,
  boost,
  fftw,
  zlib,
}:

stdenv.mkDerivation rec {
  name = "oskar";
  version = "2.12.2";

  src = fetchFromGitHub {
    owner = "OxfordSKA";
    repo = "OSKAR";
    rev = "5b2cfa87186f3275bbda06f9062e406094344628";
    sha256 = "sha256-Zy/WElLHY1ZvnNn5TqWgl2uc9yvVF0NiajFOHglVZaU=";
  };

  nativeBuildInputs = [
    cmake
    python3Packages.python
  ];
  buildInputs = [
    hdf5
    ska-sdp-func
    boost
    fftw
    zlib
    python3Packages.numpy
    python3Packages.scipy
  ];

  enableParallelBuilding = true;

  cmakeFlags = [
    "-DOSKAR_BUILD_APPS=ON"
    "-DOSKAR_BUILD_PYTHON=ON"
    "-DOSKAR_BUILD_GUI=OFF" # Disable GUI to avoid X11 dependencies
    "-DOSKAR_BUILD_DOCS=OFF"
    "-DOSKAR_BUILD_TESTS=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
    "-DFIND_CUDA=OFF" # Disable CUDA support
    "-DFIND_OPENCL=OFF" # Disable OpenCL support
  ];

  # OSKAR needs some environment variables for runtime
  propagateBuildInputs = [
    hdf5
    ska-sdp-func
  ];

  meta = with lib; {
    description = "OSKAR - A GPU-accelerated simulator for the Square Kilometre Array";
    homepage = "https://github.com/OxfordSKA/OSKAR";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ];
  };
}

{
  stdenv,
  fetchFromGitHub,
  cmake,
  hdf5,
  casacore,
  ska-sdp-func,
  python3Packages,
  boost,
  fftw,
  zlib,
  ocl-icd,
  wrapQtAppsHook ? null,
  qtbase ? null,
  withOpenCL ? false,
  withGUI ? false,
  lib,
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
    wrapQtAppsHook
  ];

  buildInputs = [
    casacore
    hdf5
    ska-sdp-func
    boost
    fftw
    zlib
  ]
  ++ (lib.optionals) (withOpenCL) [ ocl-icd ]
  ++ (lib.optionals) (withGUI) [ qtbase ];

  enableParallelBuilding = true;

  cmakeFlags = [
    "-DOSKAR_BUILD_APPS=ON"
    "-DOSKAR_BUILD_DOCS=OFF"
    "-DOSKAR_BUILD_TESTS=ON"
    "-DBUILD_TESTING=TRUE"
    "-DFIND_CUDA=OFF" # Disable CUDA support for now
    "-DFIND_OPENCL=${if (withOpenCL) then "ON" else "OFF"}"
    "-DOSKAR_BUILD_GUI=${if (withGUI) then "ON" else "OFF"}" # Disable GUI to avoid X11 dependencies
  ];

  doCheck = (withOpenCL == false); # Can not expect a GPU in the CI environment

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

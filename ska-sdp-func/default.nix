{ stdenv, python3Packages, fetchgit, cmake, boost }:

stdenv.mkDerivation rec {
  pname = "ska-sdp-func";
  version = "1.2.2";

  src = fetchgit {
    url = "https://gitlab.com/ska-telescope/sdp/ska-sdp-func.git";
    rev = "df10e082e7802c83a087de28abe94b21538be607";
    sha256 = "sha256-26Mx5bHMeO5+dWM1CAOqgwhgRH44jxsIFW3vZ0nyCdI=";
  };

  nativeBuildInputs = [ cmake ];
  
  # dontUseCmakeConfigure = true;
  
  propagatedBuildInputs = [
    python3Packages.numpy 
    python3Packages.pybind11 
  ];

  # Configure for modern Python build system
  pyproject = true;
  build-system = [ python3Packages.setuptools ];

  # Set environment variables needed for the build
  CMAKE_FLAGS = "-DCMAKE_BUILD_TYPE=RelWithDebInfo";

  meta = {
    description = "SKA SDP Processing Function Library";
    homepage = "https://gitlab.com/ska-telescope/sdp/ska-sdp-func/";
    license = "BSD-3-Clause";
    maintainers = [ ];
  };
}
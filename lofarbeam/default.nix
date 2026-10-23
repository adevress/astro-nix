{
  lib,
  buildPythonPackage,
  fetchgit,
  cmake,
  ninja,
  pkg-config,
  python,
  numpy,
  python-casacore,
  casacore,
  boost,
  openblas,
}:

buildPythonPackage rec {
  pname = "lofarbeam";
  version = "0.0.0";
  format = "other";

  src = fetchgit {
    url = "https://github.com/dguibert/LOFARBeam.git";
    rev = "7bb5b23c5efd71db4c49bc7d7856e7c504974e32";
    sha256 = "sha256-rz696nl8iAI/AWNnfjV0nPym0YnHNNT8WblYrUs5PGU=";
  };

  nativeBuildInputs = [ cmake ninja pkg-config python ];
  patches = [ ./patches/0001-std-string.patch ./patches/0002-cxx17.patch ];
  buildInputs = [ casacore boost openblas ];
  dependencies = [ numpy python-casacore ];

  pythonImportsCheck = [ "lofar.stationresponse" ];

  meta = with lib; {
    description = "LOFAR beam library";
    homepage = "https://github.com/dguibert/LOFARBeam";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ ];
  };
}

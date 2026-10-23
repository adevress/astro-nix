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
  # 0001: casacore >= 3.8.2 no longer leaks `using std::string` globally.
  # 0002/0003: casacore headers need C++17+; install the python package into
  # site-packages with an absolute RPATH instead of `$out/lofar`.
  patches = [
    ./patches/0001-std-string.patch
    ./patches/0002-cxx20.patch
    ./patches/0003-install-in-site-packages.patch
  ];

  cmakeFlags = [ "-DLOFARBEAM_PYTHON_DIR=${python.sitePackages}/" ];

  # The CMake install does not produce Python metadata: provide a minimal
  # .dist-info so that dependants' runtime-deps check (and importlib.metadata)
  # can see the package.
  postInstall = ''
    distinfo=$out/${python.sitePackages}/lofarbeam-${version}.dist-info
    mkdir -p $distinfo
    cat > $distinfo/METADATA <<EOF
    Metadata-Version: 2.1
    Name: lofarbeam
    Version: ${version}
    Requires-Dist: numpy
    Requires-Dist: python-casacore
    EOF
    echo "cmake" > $distinfo/INSTALLER
  '';
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

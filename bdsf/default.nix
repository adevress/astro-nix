# bdsf 1.14.1 — Blob Detector and Source Finder (PyBDSF).
# Required by killMS (via DDFacet[kms-support]).
{
  lib,
  buildPythonPackage,
  fetchurl,
  numpy,
  scipy,
  astropy,
  scikit-build,
  cmake,
  ninja,
  meson,
  meson-python,
  setuptools,
  setuptools-scm,
  build,
  wheel,
  gfortran,
  boost,
}:

buildPythonPackage rec {
  pname = "bdsf";
  version = "1.14.1";
  pyproject = true;

  src = fetchurl {
    name = "bdsf-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/05/86/4c808145b9e6e7bf7496f919e93eb8973c59b4359a23e3f29ab8200f079d/bdsf-${version}.tar.gz";
    sha256 = "sha256-jVET/syhm7nwKho+F6648tIscSyslQTkQnHEBx9UNNI=";
  };

  build-system = [
    build
    cmake
    meson
    ninja
    numpy
    scikit-build
    setuptools
    setuptools-scm
    wheel
  ];

  nativeBuildInputs = [
    gfortran
    cmake
    ninja
  ];

  buildInputs = [ boost ];

  # scikit-build provides FindPythonExtensions.cmake and other cmake modules.
  # Add its cmake directory to CMAKE_MODULE_PATH via CMakeLists.txt patch.
  # Also remove the 'numpy' Boost component (not available in nixpkgs boost).
  postPatch = ''
    sed -i '1a list(APPEND CMAKE_MODULE_PATH "${scikit-build}/lib/python3.13/site-packages/skbuild/resources/cmake")' CMakeLists.txt
    # Remove Python 2 backport dependency (not needed for Python 3.13)
    sed -i '/backports.shutil_get_terminal_size/d' pyproject.toml
    sed -i '/backports-shutil-get-terminal-size/d' pyproject.toml
  '';

  # Prevent nixpkgs from running its own cmake configure phase;
  # scikit-build manages cmake internally via PEP 517
  dontUseCmakeBuildDir = true;
  dontUseCmakeConfigure = true;

  dependencies = [
    numpy
    scipy
    astropy
  ];

  pythonImportsCheck = [ "bdsf" ];

  meta = with lib; {
    homepage = "https://github.com/lofar-astron/PyBDSF";
    description = "Blob Detector and Source Finder";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}

# regions 0.12 — Astropy coordinated package for region handling.
# Required by DDFacet.
{
  lib,
  buildPythonPackage,
  fetchurl,
  numpy,
  astropy,
  setuptools,
  setuptools-scm,
  cython,
  extension-helpers,
}:

buildPythonPackage rec {
  pname = "regions";
  version = "0.12";
  pyproject = true;

  src = fetchurl {
    name = "regions-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/d3/86/44ff464efa2777247d6addc74416059f1872ab05c88588bbe1aadca27a7c/regions-${version}.tar.gz";
    sha256 = "sha256-HJRgdw8lDvKZ6QqdXAs1lB99Bbv4efb/qgU4JQwBjvk=";
  };

  build-system = [
    setuptools-scm
    cython
    extension-helpers
    numpy
    setuptools
  ];

  dependencies = [
    numpy
    astropy
  ];

  pythonImportsCheck = [ "regions" ];

  meta = with lib; {
    homepage = "https://github.com/astropy/regions";
    description = "Astropy regions package for representing and manipulating regions";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ];
  };
}

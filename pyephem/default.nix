# pyephem 9.99 — Stub package that depends on ephem.
# The pyephem package on PyPI is just a stub that redirects to ephem.
# We provide it here so packages depending on "pyephem" work with nixpkgs ephem.
{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  ephem,
}:

buildPythonPackage rec {
  pname = "pyephem";
  version = "9.99";
  pyproject = true;

  src = fetchurl {
    name = "pyephem-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/8e/02/1eade827452880961bc4657df24f72e7a76d764abff3e666433e1c8d1980/pyephem-${version}.tar.gz";
    sha256 = "sha256-cINtfqt4JO8fz+ECt1HZeADUoP9oNtLllN2xwR5gix8=";
  };

  build-system = [ setuptools ];

  dependencies = [ ephem ];

  # This is a stub package that doesn't install any Python modules,
  # it just declares a dependency on ephem.
  dontCheck = true;

  meta = with lib; {
    homepage = "https://pypi.org/project/pyephem/";
    description = "Stub package that depends on ephem (astronomical ephemeris)";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}

# pdu 0.0.3 — Python Disk Usage utility.
# Required by ddf-pipeline (via treepick).
{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  wheel,
}:

buildPythonPackage rec {
  pname = "pdu";
  version = "0.0.3";
  pyproject = true;

  src = fetchurl {
    name = "pdu-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/f5/4b/f127b1867d394763beee889dcb68d84b0517db50fa551f6c0f617ce4721a/pdu-${version}.tar.gz";
    sha256 = "sha256-F4ZghfT7t8ZaXUsOUP3EmsDK0VCKhGquM23lS2G4kyo=";
  };

  build-system = [
    setuptools
    wheel
  ];

  pythonImportsCheck = [ "pdu" ];

  meta = with lib; {
    homepage = "https://github.com/tslight/pdu";
    description = "Python Disk Usage utility";
    license = licenses.isc;
    maintainers = with maintainers; [ ];
  };
}

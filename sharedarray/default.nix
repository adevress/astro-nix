# SharedArray 3.2.4 — NumPy shared memory arrays across processes.
# Required by DDFacet.
{
  lib,
  buildPythonPackage,
  fetchurl,
  numpy,
  setuptools,
  wheel,
}:

buildPythonPackage rec {
  pname = "SharedArray";
  version = "3.2.4";
  pyproject = true;

  src = fetchurl {
    name = "SharedArray-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/a6/d2/6818d35a7abba9b2410813f2160630e125b12a52ca11acfd1fb0959433ad/SharedArray-${version}.tar.gz";
    sha256 = "sha256-uLjRiREMAjud5QL5OW/yWR9mD7LJY36xP8ryMxJ+UL4=";
  };

  build-system = [
    setuptools
    wheel
    numpy
  ];

  dependencies = [ numpy ];

  pythonImportsCheck = [ "SharedArray" ];

  meta = with lib; {
    homepage = "https://gitlab.com/tenzing/shared-array";
    description = "NumPy shared memory arrays across processes";
    license = licenses.gpl2Plus;
    maintainers = with maintainers; [ ];
  };
}

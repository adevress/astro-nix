# codex-africanus 0.4.5 — Radio astronomy building blocks.
# Required by DDFacet.
{
  lib,
  buildPythonPackage,
  fetchurl,
  hatchling,
  numpy,
  numba,
  appdirs,
  decorator,
  astropy,
  dask,
  scipy,
}:

buildPythonPackage rec {
  pname = "codex-africanus";
  version = "0.4.5";
  pyproject = true;

  src = fetchurl {
    name = "codex_africanus-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/87/13/81dcc6b074398c76b4e805cb456c6362ec3a5c2a4dfb069bbf280ebd256d/codex_africanus-${version}.tar.gz";
    sha256 = "sha256-xzdIYPqYzR+G8gxXxgPuMVLr0XCrI8CBG/8PKWk3iww=";
  };

  build-system = [ hatchling ];

  dependencies = [
    appdirs
    decorator
    numpy
    numba
    astropy
    dask
    scipy
  ];

  pythonImportsCheck = [ "africanus" ];

  meta = with lib; {
    homepage = "https://github.com/ratt-ru/codex-africanus";
    description = "Radio Astronomy Building Blocks";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ];
  };
}

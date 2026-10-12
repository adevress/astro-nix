# meqtrees-cattery 1.8.0 — MeqTrees Cattery library.
# Required by DDFacet[fits-beam-support].
{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  wheel,
  numpy,
  scipy,
  astropy,
  python-casacore,
  purr,
}:

buildPythonPackage rec {
  pname = "meqtrees-cattery";
  version = "1.8.0";
  pyproject = true;

  src = fetchurl {
    name = "meqtrees_cattery-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/9c/f1/a73ddc421e7349f77f564000760a95a953d066740a08ca2d2c2516759b45/meqtrees_cattery-${version}.tar.gz";
    sha256 = "sha256-w7G8ozOFspr8xlsuSw+JzhKTYJ0eerp3a0+eeplvNro=";
  };

  build-system = [
    setuptools
    wheel
  ];

  # Remove astro_kittens dependency (not in nixpkgs, optional GUI dependency)
  postPatch = ''
    sed -i "s/    'astro_kittens'//" setup.py
    sed -i "s/    'astro_kittens',//" setup.py
    sed -i "/astro_kittens/d" setup.py
  '';

  dependencies = [
    numpy
    scipy
    astropy
    python-casacore
    purr
  ];

  pythonImportsCheck = [ "Cattery" ];

  meta = with lib; {
    homepage = "https://github.com/ska-sa/meqtrees-cattery";
    description = "MeqTrees Cattery library for radio astronomy";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}

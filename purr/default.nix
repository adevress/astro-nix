# purr 1.5.3 — Logging utilities for radio astronomy.
# Required by meqtrees-cattery.
{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  wheel,
  scipy,
  astropy,
  pillow,
}:

buildPythonPackage rec {
  pname = "purr";
  version = "1.5.3";
  pyproject = true;

  src = fetchurl {
    name = "purr-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/d8/3e/44e0b78414951f985d7ab42de2c87f5ba7c7123480f47f9963e65f9cdbca/purr-${version}.tar.gz";
    sha256 = "sha256-wiYIqvlPjls4Gqd5yBfa6xhqUGsRR7zbLiojjXIrT6A=";
  };

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [
    scipy
    astropy
    pillow
  ];

  # Remove kittens (not in nixpkgs) and future (not supported on Python 3.13)
  postPatch = ''
    sed -i "s/install_requires=\['kittens', 'pillow', 'scipy', 'astropy', 'future'\]/install_requires=['pillow', 'scipy', 'astropy']/" setup.py
  '';

  # Purr imports Kittens at module level (optional GUI dependency not in nixpkgs)
  doCheck = false;
  pythonImportsCheck = [ ];

  meta = with lib; {
    homepage = "https://github.com/ska-sa/purr";
    description = "Logging utilities for radio astronomy";
    license = licenses.gpl2;
    maintainers = with maintainers; [ ];
  };
}

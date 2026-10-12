# treepick 0.1.4 — Curses tree style path picker.
# Required by ddf-pipeline.
{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  wheel,
  pdu,
}:

buildPythonPackage rec {
  pname = "treepick";
  version = "0.1.4";
  pyproject = true;

  src = fetchurl {
    name = "treepick-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/de/10/b5ad45a24a132b8e8a7ff0fab0b77ba52950eb973f0bdaf2dd4c64153cde/treepick-${version}.tar.gz";
    sha256 = "sha256-sWjh8QjWil6cM4dExgAKSFjc5orUbmrcHGHaeuAjtxo=";
  };

  build-system = [
    setuptools
    wheel
  ];

  dependencies = [ pdu ];

  # cgitb was removed in Python 3.13
  postPatch = ''
    sed -i '/import cgitb/d' treepick/pick.py
    sed -i '/cgitb.enable/d' treepick/pick.py
  '';

  pythonImportsCheck = [ "treepick" ];

  meta = with lib; {
    homepage = "https://github.com/tslight/treepick";
    description = "Curses tree style path picker";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}

# yorn 0.0.6 — A boringly simple CLI input function.
# Required by ddf-pipeline.
{
  lib,
  buildPythonPackage,
  fetchurl,
  setuptools,
  wheel,
}:

buildPythonPackage rec {
  pname = "yorn";
  version = "0.0.6";
  pyproject = true;

  src = fetchurl {
    name = "yorn-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/9a/21/02824a5beb10b88cc7bf9a790b69ece00abba2c35031d3937629982b82d6/yorn-${version}.tar.gz";
    sha256 = "sha256-lmyJeNDe9NLogQhvT1Sl8sYBy8BDjDh0ln4tr0gp9NM=";
  };

  build-system = [
    setuptools
    wheel
  ];

  pythonImportsCheck = [ "yorn" ];

  meta = with lib; {
    homepage = "https://github.com/tslight/yorn";
    description = "A boringly simple CLI input function";
    license = licenses.isc;
    maintainers = with maintainers; [ ];
  };
}

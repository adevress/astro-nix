# pyFFTW 0.15.1 — Python wrapper for the FFTW library.
# Required by DDFacet.
{
  lib,
  buildPythonPackage,
  fetchurl,
  numpy,
  scipy,
  cython,
  setuptools,
  setuptools-scm,
  wheel,
  fftw,
  fftwFloat,
}:

buildPythonPackage rec {
  pname = "pyFFTW";
  version = "0.15.1";
  pyproject = true;

  src = fetchurl {
    name = "pyfftw-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/f2/2d/e38439b7f937e8bf91a9ff2b8d9713d0d8e64e980fc00e8d1945b8a5b74b/pyfftw-${version}.tar.gz";
    sha256 = "sha256-u83m1A0WXhy68S3eBi6/6+nkM5TKyMFm5pm6LJpLBGE=";
  };

  build-system = [
    wheel
    setuptools
    setuptools-scm
    cython
    numpy
  ];

  buildInputs = [
    fftw
    fftwFloat
  ];

  dependencies = [
    numpy
    scipy
  ];

  # pyFFTW setup looks for fftw3.h and libfftw3 in standard locations
  preBuild = ''
    export CFLAGS="$CFLAGS -I${fftw.dev}/include"
    export LDFLAGS="$LDFLAGS -L${fftw}/lib -L${fftwFloat}/lib"
  '';

  pythonImportsCheck = [ "pyfftw" ];

  meta = with lib; {
    homepage = "https://github.com/pyFFTW/pyFFTW";
    description = "Python wrapper for the FFTW library";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ];
  };
}

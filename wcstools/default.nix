{ stdenv, fetchurl, cfitsio }:

stdenv.mkDerivation rec {
  name = "wcstools";
  version = "3.9.7";

  src = fetchurl {
    url = "http://tdc-www.harvard.edu/software/wcstools/wcstools-3.9.7.tar.gz";
    sha256 = "525f6970eb818f822db75c1526b3122b1af078affa572dce303de37df5c7b088";
  };

  buildInputs = [ cfitsio ];

  installPhase = ''
    mkdir -p $out/bin
    install -m755 bin/* $out/bin/
    
    mkdir -p $out/share/man/man1
    install -m644 man/man1/* $out/share/man/man1/
  '';

  meta = {
    description = "WCSTools - Utilities for the FITS World Coordinate System";
    homepage = "http://tdc-www.harvard.edu/software/wcstools";
    license = "lgpl21";
    maintainers = [ ];
  };
}
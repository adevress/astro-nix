{
  stdenv,
  fetchurl,
  perl,
  zip,
  autoconf,
  tcl,
  tk,
  libX11,
  zlib,
  libxml2,
  libxslt,
  openssl,
  lib,
  makeWrapper,
}:

stdenv.mkDerivation rec {
  name = "ds9";
  version = "8.7";

  src = fetchurl {
    url = "https://ds9.si.edu/download/source/ds9.${version}.tar.gz";
    sha256 = "sha256-eABxXwIKRQnYMyNpFOoxkK+PHii7ApSClJTj5/oz92g=";
  };

  nativeBuildInputs = [
    perl
    autoconf
    zip
  ];
  buildInputs = [
    tcl
    tk
    libX11
    zlib
    libxml2
    libxslt
    openssl
  ];

  enableParallelBuilding = true;

  # DS9 uses a custom build system
  configurePhase = ''

    ./unix/configure \
      --prefix=$out \
      --exec-prefix=$out \
      --with-tcl=${tcl} \
      --with-tk=${tk} \
      --with-x \
      --enable-64bit
  '';

  makeFlags = [
    "XML2CONFIG=${libxml2.dev}/bin/xml2-config"
    "XSLTCONFIG=${libxslt.dev}/bin/xslt-config"
  ];

  installPhase = ''
    find ./bin/ -type f | xargs -I {} install -D {} $out/{}
    find ./lib/ -type f | grep -v "a$" | xargs -I {} install -D {} $out/{}    
  '';

  dontFixup = true;

  meta = with lib; {
    description = "SAOImage DS9 - Astronomical imaging and data visualization application";
    homepage = "https://ds9.si.edu/";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}

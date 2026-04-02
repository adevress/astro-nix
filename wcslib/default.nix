{
  stdenv,
  fetchurl,
  cfitsio,
  lib,
}:

stdenv.mkDerivation rec {
  name = "wcslib-8.5";
  version = "8.5";

  src = fetchurl {
    url = "https://www.atnf.csiro.au/computing/software/wcs/wcslib-releases/wcslib-8.5.tar.bz2";
    sha256 = "sha256-8f0bePv9ur2jY/gEXgxZ4yc17KRUgqUwIZHlb+Bi6s4=";
  };

  nativeBuildInputs = [ cfitsio ];

  configureFlags = [
    "--enable-fits"
    "--enable-wcslib-old-c-api"
  ];

  meta = with lib; {
    description = "WCSLIB - Library for parsing and manipulating FITS World Coordinate System transformations";
    homepage = "https://www.atnf.csiro.au/computing/software/wcslib/";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}

{
  stdenv,
  fetchFromGitHub,
  cmake,
  casacore,
  gsl,
  boost,
  lib,
}:

stdenv.mkDerivation rec {
  name = "dysco";
  version = "2024-03-29"; # Using date as version since no tagged releases

  src = fetchFromGitHub {
    owner = "aroffringa";
    repo = "dysco";
    rev = "36b61add9b88be4a6c65722a0418d47c37af9035";
    sha256 = "10xmx3rkz4ra660yv1w2c18589sxbmhh64fq2y5vlqf1b3s8rjyq";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    casacore
    gsl
    boost
  ];

  cmakeFlags = [
    "-DPORTABLE=ON"
    "-DBUILD_PACKAGES=OFF"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "Dysco - A compressing storage manager for Casacore measurement sets";
    homepage = "https://github.com/aroffringa/dysco";
    license = licenses.gpl3; # Based on the LICENSE file in the repo
    maintainers = with maintainers; [ ];
  };
}

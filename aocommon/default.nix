{ stdenv, fetchgit, cmake, xtensor, boost, casacore, openblas, hdf5, cfitsio, doxygen ? null, lib }:

stdenv.mkDerivation rec {
  name = "aocommon";
  version = "dev"; 

  src = fetchgit {
    url = "https://gitlab.com/aroffringa/aocommon.git";
    rev = "8a464c5441c4121bf578adc21349ed990970b587";
    sha256 = "sha256-vVKeTmBIsFUlNqYqcS0lUeztYK5KBsnr66YyuJoMWEs=";
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ cfitsio xtensor boost casacore openblas hdf5 ] ++ (if doxygen != null then [ doxygen ] else []);

  patches = [ ./xtensor-path2.patch ];

  cmakeFlags = [
    "-DFETCHCONTENT_FULLY_DISCONNECTED=TRUE"
    "-DPORTABLE=TRUE"
    "-DBUILD_TESTING=OFF"
  ];

  installPhase = ''
    pushd $src
    find include/aocommon -type f | xargs -I {} install -Dm644 {} $out/{} 
  '';

  meta = with lib; {
    description = "Astronomical Common Library";
    homepage = "https://gitlab.com/aroffringa/aocommon";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}
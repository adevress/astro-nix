{ stdenv, fetchgit, cmake, pkg-config, xtensor, boost, casacore, openblas, hdf5, cfitsio, doxygen ? null, lib }:

stdenv.mkDerivation rec {
  name = "aocommon";
  version = "dev"; 

  src = fetchgit {
    url = "https://gitlab.com/aroffringa/aocommon.git";
    rev = "8d28d5d6e2a915279e8193830c900f30fc2bdda5";
    sha256 = "sha256-JxCdez6rD9KVytcNEuH0zmG8nQDd492qx6g6wucD34s=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ cfitsio casacore  boost hdf5 ] ++ (if doxygen != null then [ doxygen ] else []);
  propagatedBuildInputs = [ xtensor openblas casacore ];

  patches = [ ./xtensor-path2.patch ];

  cmakeFlags = [
    "-DFETCHCONTENT_FULLY_DISCONNECTED=TRUE"
    "-DPORTABLE=TRUE"
    "-DBUILD_TESTING=ON"
  ];

  installPhase = ''
    pushd $src
    # header only, copy headers
    find include/aocommon -type f | xargs -I {} install -Dm644 {} $out/{} 
    # Some project seems to expect the CMake module
    find CMake/ -type f | xargs -I {} install -Dm644 {} $out/{}
  '';

  meta = with lib; {
    description = "Astronomical Common Library";
    homepage = "https://gitlab.com/aroffringa/aocommon";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}

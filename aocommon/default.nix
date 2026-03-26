{ stdenv, fetchgit, cmake, pkg-config, xtensor, boost, casacore, openblas, hdf5, cfitsio, doxygen ? null, lib }:

stdenv.mkDerivation rec {
  name = "aocommon";
  version = "dev"; 

  src = fetchgit {
    url = "https://gitlab.com/aroffringa/aocommon.git";
    rev = "fe270d5d7b7224a318017920da3096e81fd278e1";
    sha256 = "sha256-u+1boSpVSugcFgXQzG+zJNo2KgZSFh5zLSRWUTlEhQs=";
  };

  nativeBuildInputs = [ cmake pkg-config ];
  buildInputs = [ cfitsio casacore  boost hdf5 ] ++ (if doxygen != null then [ doxygen ] else []);
  propagatedBuildInputs = [ xtensor openblas casacore ];

  cmakeFlags = [
    "-DFETCHCONTENT_FULLY_DISCONNECTED=TRUE"
    "-DPORTABLE=TRUE"
    "-DBUILD_TESTING=ON"
  ];

  installPhase = ''
    pushd ../
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

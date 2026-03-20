{ stdenv, fetchgit, cmake, hdf5, fftw, python3Packages, doxygen ? null, lib }:

stdenv.mkDerivation rec {
  name = "schaapcommon";
  version = "1.0.0"; # TODO: update with correct version

  src = fetchgit {
    url = "https://git.astron.nl/RD/schaapcommon.git";
    rev = "4bc5d9be48513f1c3d80955f8c7e5c087404bc3f";
    sha256 = "0000000000000000000000000000000000000000000000000000"; # TODO: update with correct hash
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ hdf5 fftw python3Packages.python python3Packages.pybind11 ] ++ (if doxygen != null then [ doxygen ] else []);

  cmakeFlags = [
    "-DBUILD_TESTING=OFF"
  ];

  meta = with lib; {
    description = "SchaapCommon - Common libraries for radio astronomy";
    homepage = "https://git.astron.nl/RD/schaapcommon";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}
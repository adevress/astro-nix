{ stdenv, casacore, aocommon, fetchgit, boost, gsl, cmake, hdf5, fftw, fftwFloat,python3Packages, doxygen ? null, lib }:

stdenv.mkDerivation rec {
  name = "schaapcommon";
  version = "0.1.0-dev";

  src = fetchgit {
    url = "https://git.astron.nl/RD/schaapcommon.git";
    rev = "4bc5d9be48513f1c3d80955f8c7e5c087404bc3f";
    sha256 = "sha256-usYXlhcVXFVOl6rN0FDvcUht6sjD2Xm4ccLwDiugA6o="; # TODO: update with correct hash
  };

  patches = [ ./schapcommon-xtensor-path.patch ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [ hdf5 fftw fftwFloat boost gsl python3Packages.python python3Packages.pybind11 casacore aocommon ] ++ (if doxygen != null then [ doxygen ] else []);

  cmakeFlags = [
    "-DFETCHCONTENT_FULLY_DISCONNECTED=TRUE"
    "-DAOCOMMON_INCLUDE_DIR=${aocommon}/include/"
  ];

  meta = with lib; {
    description = "SchaapCommon - Common libraries for radio astronomy";
    homepage = "https://git.astron.nl/RD/schaapcommon";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}
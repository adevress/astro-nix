{ stdenv, fetchgit, cfitsio, cmake, aocommon, schaapcommon, casacore, hdf5, boost, fftw, fftwFloat, gsl, python3Packages, doxygen ? null, lib }:

stdenv.mkDerivation rec {
  name = "radler";
  version = "1.0.0";

  src = fetchgit {
    url = "https://git.astron.nl/RD/radler.git";
    rev = "v${version}";
    sha256 = "sha256-CsUoLSQ3GN4JJuqHGnLrkKVy3ReOukDVQ03bOYWK5Ag"; # TODO: update with correct hash
    fetchSubmodules = false;
  };

  nativeBuildInputs = [ cmake ];
  buildInputs = [ schaapcommon casacore cfitsio boost hdf5 fftw fftwFloat gsl python3Packages.python python3Packages.pybind11 ] ++ (if doxygen != null then [ doxygen ] else []);

  cmakeFlags = [
    "-DFETCHCONTENT_FULLY_DISCONNECTED=TRUE"
    "-DCOMPILE_AS_EXTERNAL_PROJECT=ON"
    "-DPORTABLE=ON"
    "-DBUILD_PYTHON_BINDINGS=ON"
    "-DBUILD_DOCUMENTATION=OFF"
    "-DBUILD_DOCSTRINGS=OFF"
    "-DAOCOMMON_INCLUDE_DIR=${aocommon}/include/"
    "-DSCHAAPCOMMON_SOURCE_DIR=${schaapcommon}/"
    "-DCASACORE_ROOT_DIR=${casacore}/"
  ];

  patches = [ ./radler-set-cpu-flag.patch ];

  meta = with lib; {
    description = "Radler - Radio Astronomy Data Library for Efficient Reduction";
    homepage = "https://git.astron.nl/RD/radler";
    license = licenses.lgpl3;
    maintainers = with maintainers; [ ];
  };
}

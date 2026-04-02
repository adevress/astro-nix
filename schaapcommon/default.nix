{
  stdenv,
  aocommon,
  fetchgit,
  boost,
  gsl,
  cmake,
  hdf5,
  fftw,
  fftwFloat,
  python3Packages,
  doxygen ? null,
  lib,
}:

stdenv.mkDerivation rec {
  name = "schaapcommon";
  version = "0.1.0-dev";

  src = fetchgit {
    url = "https://git.astron.nl/RD/schaapcommon.git";
    rev = "4bc5d9be48513f1c3d80955f8c7e5c087404bc3f";
    sha256 = "sha256-usYXlhcVXFVOl6rN0FDvcUht6sjD2Xm4ccLwDiugA6o="; # TODO: update with correct hash
  };

  patches = [
    ./schapcommon-xtensor-path.patch
    ./schapcommon-dep-reso.patch
  ];

  nativeBuildInputs = [ cmake ];
  buildInputs = [
    hdf5
    fftw
    fftwFloat
    boost
    gsl
    python3Packages.python
    python3Packages.pybind11
  ]
  ++ (if doxygen != null then [ doxygen ] else [ ]);
  propagatedBuildInputs = [ aocommon ];

  cmakeFlags = [
    "-DFETCHCONTENT_FULLY_DISCONNECTED=TRUE"
    "-DAOCOMMON_INCLUDE_DIR=${aocommon}/include/"
  ];

  installPhase = ''
    cd ../
    # copy source directory to target
    find ./ -type f | xargs -I {} install -Dm644 {} $out/{}
  '';

  meta = with lib; {
    description = "SchaapCommon - Common libraries for radio astronomy";
    homepage = "https://git.astron.nl/RD/schaapcommon";
    license = licenses.gpl3;
    maintainers = with maintainers; [ ];
  };
}

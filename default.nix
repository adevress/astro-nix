let
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.11.tar.gz";
    sha256 = "1zn1lsafn62sz6azx6j735fh4vwwghj8cc9x91g5sx2nrg23ap9k";
  }) { };

  astro_pkgs = rec {

    hello = pkgs.callPackage ./hello/default.nix { };

    # specialization of packaged
    openblasSingleThreaded = pkgs.openblas.override { singleThreaded = true; };

    # Astronomy packages
    wcstools = pkgs.callPackage ./wcstools/default.nix { };
    wcslib = pkgs.callPackage ./wcslib/default.nix { };
    casacore = pkgs.callPackage ./casacore/default.nix {
      openblas = openblasSingleThreaded;
      inherit wcslib;
    };
    aocommon = pkgs.callPackage ./aocommon/default.nix {
      openblas = openblasSingleThreaded;
      inherit casacore;
    };
    schaapcommon = pkgs.callPackage ./schaapcommon/default.nix { inherit aocommon; };
    radler = pkgs.callPackage ./radler/default.nix { inherit aocommon schaapcommon casacore; };
    wsclean = pkgs.callPackage ./wsclean/default.nix {
      inherit
        aocommon
        radler
        schaapcommon
        idg
        ;
      ska-sdp-func = null;
    };
    ska-sdp-func = pkgs.callPackage ./ska-sdp-func/default.nix { };
    xtensor-fftw = pkgs.callPackage ./xtensor-fftw/default.nix { };
    everybeam = pkgs.callPackage ./everybeam/default.nix {
      inherit aocommon schaapcommon ska-sdp-func;
    };
    idg = pkgs.callPackage ./idg/default.nix { inherit aocommon schaapcommon; };
    dysco = pkgs.callPackage ./dysco/default.nix { inherit casacore; };
    oskar = pkgs.callPackage ./oskar/default.nix { inherit ska-sdp-func; };
  };

  py_astro_pkgs = rec {

    python3Packages = pkgs.python3Packages // rec {
      radler = astro_pkgs.radler.override { pythonBuild = true; };
    };

    astroPyEnv = pkgs.python3Packages.python.withPackages (ps: [
      python3Packages.radler
      ps.scipy
      ps.numpy
      ps.matplotlib
      ps.astropy
    ]);
  };

in
{
  upstream_pkgs ? pkgs,
}:
pkgs // astro_pkgs // py_astro_pkgs

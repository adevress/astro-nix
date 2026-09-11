{
  system ? builtins.currentSystem,
  upstream_pkgs ? null,
}:
let
  pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.11.tar.gz";
    sha256 = "1zn1lsafn62sz6azx6j735fh4vwwghj8cc9x91g5sx2nrg23ap9k";
  }) { inherit system; };

  astro_pkgs = rec {

    hello = pkgs.callPackage ./hello/default.nix { };

    # Meson >= 1.11 override (upstream nixpkgs recipe, version bumped; CyberEther needs it)
    meson = pkgs.callPackage ./meson/default.nix { };

    # CyberEther meson subproject bundles (flat namespace; sources pinned to
    # the exact revisions CyberEther's .wrap files commit)
    fmt = pkgs.callPackage ./fmt/default.nix { };
    glfw = pkgs.callPackage ./glfw/default.nix { };
    glm = pkgs.callPackage ./glm/default.nix { };
    rapidyaml = pkgs.callPackage ./rapidyaml/default.nix { };
    cpp-httplib = pkgs.callPackage ./cpp-httplib/default.nix { };
    nlohmann_json = pkgs.callPackage ./nlohmann_json/default.nix { };
    qrencode = pkgs.callPackage ./qrencode/default.nix { };
    nanobench = pkgs.callPackage ./nanobench/default.nix { };
    nanobind = pkgs.callPackage ./nanobind/default.nix { };
    robin-map = pkgs.callPackage ./robin-map/default.nix { };
    libmodes = pkgs.callPackage ./libmodes/default.nix { };
    stb = pkgs.callPackage ./stb/default.nix { };

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
    oskar = pkgs.callPackage ./oskar/default.nix { inherit ska-sdp-func casacore; };
    oskarWithGUI = pkgs.libsForQt5.callPackage ./oskar/default.nix {
      withGUI = true;
      inherit casacore ska-sdp-func;
    };
    aoflagger = pkgs.callPackage ./aoflagger/default.nix { inherit aocommon; };
    ds9 = pkgs.callPackage ./ds9/default.nix { };
    cyberether = pkgs.callPackage ./cyberether/default.nix {
      inherit
        meson
        fmt
        glfw
        glm
        rapidyaml
        cpp-httplib
        nlohmann_json
        qrencode
        nanobench
        nanobind
        robin-map
        libmodes
        stb
        ;
      geodata = pkgs.callPackage ./cyberether/geodata/default.nix { };
    };
  };

  py_astro_pkgs = rec {

    python3Packages = pkgs.python3Packages // rec {
      radler = astro_pkgs.radler.override { pythonBuild = true; };
      xtensor-python = pkgs.callPackage ./xtensor-python/default.nix { };
      mapbox-earcut = pkgs.callPackage ./mapbox-earcut/default.nix {
        inherit (pkgs.python3Packages)
          buildPythonPackage
          scikit-build-core
          nanobind
          numpy
          pathspec
          ;
        cmake = pkgs.cmake;
        ninja = pkgs.ninja;
      };
    };

    astroPyEnv = pkgs.python3Packages.python.withPackages (ps: [
      python3Packages.radler
      python3Packages.mapbox-earcut
      ps.scipy
      ps.numpy
      ps.dask
      ps.xarray
      ps.matplotlib
      ps.astropy
    ]);
  };

in
let
  pkgSet = pkgs // astro_pkgs // py_astro_pkgs;

  # CyberEther's geodata step (resources/geodata) requires a python with
  # numpy + mapbox_earcut; give the build the full interpreted env.
  cyberetherPython = pkgSet.python3Packages.python.withPackages (ps: [
    pkgSet.python3Packages.numpy
    pkgSet.python3Packages.mapbox-earcut
  ]);
in
pkgSet
// {
  cyberether = pkgSet.cyberether.override { python3 = cyberetherPython; };
}

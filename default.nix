

let
  upstream_pkgs = import (fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.11.tar.gz";
    sha256 = "1zn1lsafn62sz6azx6j735fh4vwwghj8cc9x91g5sx2nrg23ap9k";
  }) {};
  
in
{ pkgs ? upstream_pkgs }: 

pkgs // rec {

  hello = pkgs.callPackage ./hello/default.nix {};

  # specialization of packaged
  openblasSingleThreaded = pkgs.openblas.override { singleThreaded = true; };

  # Astronomy packages
  wcstools = pkgs.callPackage ./wcstools/default.nix {};
  wcslib = pkgs.callPackage ./wcslib/default.nix {};
  casacore = pkgs.callPackage ./casacore/default.nix { 
    openblas = openblasSingleThreaded;
    inherit wcslib;
  };
  aocommon = pkgs.callPackage ./aocommon/default.nix { 
    openblas = openblasSingleThreaded;
    inherit casacore; 
  };
  schaapcommon = pkgs.callPackage ./schaapcommon/default.nix {inherit aocommon; };
  radler = pkgs.callPackage ./radler/default.nix { inherit aocommon schaapcommon casacore; };
  wsclean = pkgs.callPackage ./wsclean/default.nix { inherit aocommon radler schaapcommon; };
  ska-sdp-func = pkgs.callPackage ./ska-sdp-func/default.nix {};
  everybeam = pkgs.callPackage ./everybeam/default.nix { inherit aocommon schaapcommon ska-sdp-func; };

}

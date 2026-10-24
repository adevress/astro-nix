final: prev: 
let
  pkgs = prev.pkgs;
in
{
  astroPkgs = import ./all_packages.nix { lib = prev.lib; inherit pkgs; };
}

final: prev: 
let
  pkgs = prev.pkgs;
in
{
  astroPkgs = import ./scope.nix { lib = prev.lib; inherit pkgs; };
}

{
  description = "astro-nix — Nix recipes for astronomy & radio astronomy";

  outputs =
    { self }:
    let
      # Platforms covered by the CI cache (x86_64 + aarch64 Linux).
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      # Import the repo's full package set. default.nix pins its own nixpkgs
      # (25.11) and merges it with the repo's astro/python packages, so the
      # result already contains both the upstream packages (e.g. libusb) and
      # the repo's own ones (e.g. wsclean, cyberether).
      # `system` is passed explicitly so the flake evaluates purely; for legacy
      # `nix -f ./` usage default.nix falls back to builtins.currentSystem.
      mkPkgs = system: import ./default.nix { inherit system; };
    in
    {
      # Expose the whole set under legacyPackages so `nix search . <pkg>`
      # finds anything provided by astro-nix or its upstream nixpkgs source.
      # legacyPackages (rather than packages) is used because the full
      # nixpkgs set contains attributes that deliberately fail to evaluate;
      # nix search tolerates those per-attribute failures here.
      legacyPackages = builtins.listToAttrs (
        map (system: {
          name = system;
          value = mkPkgs system;
        }) systems
      );
    };
}

{
  system ? builtins.currentSystem,
  upstream_pkgs ? null,
  # Astro-nix build configuration.  Defaults to ./config.nix; pass a partial
  # attrset to override individual settings, e.g.
  #   nix build -f . cuda-hello --arg config '{ cudaArch = [ "sm_121" ]; }'
  config ? { },
}:
let
  astroConfig = (import ./config.nix) // config;

  # CUDA redistributables (cudaPackages) are unfree; NixGpu and cuda-hello
  # need them.  Nothing here builds an unfree package unless asked to.
  # `cudaArch` is an astro-nix setting, not a nixpkgs one, so it is not
  # forwarded to the nixpkgs import.
  pkgs =
    import
      (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.11.tar.gz";
        sha256 = "1zn1lsafn62sz6azx6j735fh4vwwghj8cc9x91g5sx2nrg23ap9k";
      })
      {
        inherit system;
        config = builtins.removeAttrs astroConfig [ "cudaArch" ];
      };
  pkgSet = import ./all_packages.nix { lib = pkgs.lib; inherit pkgs; };
in pkgSet

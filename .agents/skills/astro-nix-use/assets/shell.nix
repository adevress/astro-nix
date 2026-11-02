# shell.nix — radio interferometry environment from astro-nix
#
# Enter the environment with plain:
#
#   nix-shell
#
# The `astroSrc` binding below is the <astro_nix> pointer (see SKILL.md §0):
# it defaults to the GitHub tarball URL, so no clone is needed. To use a local
# git clone instead (e.g. after editing recipes), replace astroSrc with the
# clone path:
#
#   astroSrc = /path/to/astro-nix;   # <astro_nix> = local clone
#
# For reproducibility, pin a commit:
#   astroSrc = "https://github.com/adevress/astro-nix/archive/<full-sha>.tar.gz";
# and add its `sha256 = "..."` to the fetchTarball call below.
#
# Flake alternative (recommended for projects): see SKILL.md §4 —
# inputs.astro-nix + nixpkgs.overlays = [ astro-nix.overlays.default ].

let
  # <astro_nix>: tarball URL (default, no clone) or a local clone path.
  astroSrc = "https://github.com/adevress/astro-nix/archive/refs/heads/main.tar.gz";

  astro =
    if builtins.substring 0 4 astroSrc == "http"
    then import (builtins.fetchTarball astroSrc) { }
    else import astroSrc { };

  # mkShell is not part of the astro-nix set (which contains only astro packages);
  # take it from nixpkgs — pinned to the same release 25.11 that astro-nix's
  # default.nix uses, so derivations stay compatible.
  pkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.11.tar.gz";
    sha256 = "1zn1lsafn62sz6azx6j735fh4vwwghj8cc9x91g5sx2nrg23ap9k";
  }) { };

  # Custom Python stack: astro-nix exposes `python3Packages` as upstream
  # python3Packages extended with the astro bindings (radler, ...).
  pythonEnv = astro.python3Packages.python.withPackages (ps: [
    ps.radler          # radio deconvolution python bindings (pythonBuild = true)
    ps.astropy
    ps.numpy
    ps.scipy
    ps.matplotlib
    ps.dask
    ps.xarray
  ]);
in
pkgs.mkShell {
  packages = with astro; [
    # Measurement sets & flagging
    casacore           # readms, taql, ms tools
    dysco              # MS compression
    aoflagger          # RFI flagger

    # Calibration / imaging
    wsclean            # imager
    everybeam          # beam models

    # Visualization
    ds9                # FITS viewer

    # Python analysis stack (from the let binding above)
    pythonEnv
  ];

  shellHook = ''
    echo "astro-nix environment ready: wsclean, aoflagger, casacore, everybeam, ds9, python3+astropy"
  '';
}

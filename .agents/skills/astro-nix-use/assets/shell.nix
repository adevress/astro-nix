# shell.nix — radio interferometry environment from astro-nix
#
# Usage:
#   1. Adjust the path below, or use the fetchTarball variant to pin a revision.
#   2. Run `nix-shell` in this directory (or `nix develop -f shell.nix` is not
#      needed here; plain `nix-shell` reads this file).
#
# Pinned variant for reproducibility:
#   astro = import (fetchTarball {
#     url = "https://github.com/adevress/astro-nix/archive/<rev>.tar.gz";
#     sha256 = "<sha256>";
#   }) {};

let
  astro = import /path/to/astro-nix {};

  # Custom Python stack: astro-nix exposes `python3Packages` as upstream
  # python3Packages extended with radler (pythonBuild = true) and friends.
  pythonEnv = astro.python3Packages.python.withPackages (ps: [
    astro.python3Packages.radler   # radio deconvolution python bindings
    ps.astropy
    ps.numpy
    ps.scipy
    ps.matplotlib
    ps.dask
    ps.xarray
  ]);
in
astro.mkShell {
  packages = with astro; [
    # Measurement sets & flagging
    casacore        # readms, taql, ms tools
    dysco           # MS compression
    aoflagger       # RFI flagger

    # Calibration / imaging
    wsclean         # imager
    everybeam       # beam models

    # Visualization
    ds9             # FITS viewer

    # Python analysis stack
    pythonEnv
  ];

  shellHook = ''
    echo "astro-nix environment ready: wsclean, aoflagger, casacore, everybeam, ds9, python3+astropy"
  '';
}

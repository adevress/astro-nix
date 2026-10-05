# cotter — André Offringa's MWA pre-processing pipeline.
#
# Provides the two binaries used by the MWA uvfits->MS recipe in
#   data/mwa/full/dataset_all_references.md
#     * cotter    : raw GPU files -> Measurement Set (not needed for that recipe)
#     * fixmwams  : fix the MWA keywords of an MS produced by CASA importuvfits
#
# Replaces `docker run ... mwatelescope/cotter fixmwams <ms> <metafits>`.
#
# Upstream is only tested through its Dockerfile (Ubuntu + system casacore,
# aoflagger, cfitsio, boost, starlink pal); this recipe feeds it the astro-nix
# versions of casacore/aoflagger and the astro-nix `pal` recipe.
{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  pkg-config,
  boost,
  cfitsio,
  casacore,
  aoflagger,
  pal,
}:

stdenv.mkDerivation rec {
  name = "cotter";
  version = "4.6-unstable-2026-05-12"; # master, tip of 2026-05-12

  src = fetchFromGitHub {
    owner = "MWATelescope";
    repo = "cotter";
    rev = "56f532f8772e137d1b61d8f02ee7532a6a66cd05";
    sha256 = "sha256-v3Qd+EsP024RXh24/ycx5b6kdkXoiKwQwk3HHFfuoF0=";
  };

  # Upstream CMake hard-codes -march=x86-64 (PORTABLE=ON) / -march=native
  # (PORTABLE=OFF).  The former does not compile on aarch64, the latter would
  # make CI-cached binaries depend on the build host CPU.  Drop both.
  patches = [ ./001-portable-march.patch ];

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    casacore
    aoflagger
    cfitsio
    boost
    pal
  ];

  cmakeFlags = [
    # FindCasacore / FindCFITSIO only look at these hints (plus the default
    # prefix path); point them explicitly at the Nix store paths.
    "-DCASACORE_ROOT_DIR=${casacore}"
    "-DCFITSIO_ROOT_DIR=${cfitsio}"
    # aoflagger installs its config as share/aoflagger/cmake/aoflagger-config.cmake
    # and defines AOFLAGGER_INCLUDE_DIR / AOFLAGGER_LIB, which cotter links against.
    "-DAOFlagger_DIR=${aoflagger}/share/aoflagger/cmake"
    # cotter only declares cmake_minimum_required(VERSION 3.5); nixpkgs 25.11
    # ships CMake 4.x which would otherwise refuse very old project defaults.
    "-DCMAKE_POLICY_VERSION_MINIMUM=3.5"
    # gtkmm-3.0 / sigc++ are probed with pkg_check_modules(... gtkmm-3.0>=3.0.0)
    # without REQUIRED and are never used by cotter or fixmwams: leaving them
    # out of buildInputs keeps the GUI probe (correctly) false.
  ];

  enableParallelBuilding = true;

  # Upstream ships no LICENSE file; the Dockerfile is what defines the
  # supported dependency set.  meta.license is therefore left unset on purpose.
  meta = with lib; {
    description = "MWA pre-processing pipeline: cotter and fixmwams";
    homepage = "https://github.com/MWATelescope/cotter";
    platforms = platforms.linux;
    maintainers = with maintainers; [ ];
  };
}

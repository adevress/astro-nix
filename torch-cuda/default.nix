# CUDA-enabled PyTorch binary for Linux (aarch64 NVIDIA GB10 / sm_121 and
# x86_64).
#
# Nixpkgs' `torch-bin` ships the CPU wheel on aarch64-linux and a CUDA 12.8
# wheel on x86_64-linux.  PyTorch publishes official CUDA 13.0 wheels for both
# platforms, so instead of compiling PyTorch from source (hours, and fragile on
# sm_121) we reuse the upstream cu130 wheel and satisfy its CUDA runtime from
# nixpkgs cudaPackages_13_0.
#
# The result is used by the cross-instrument Transformer codec experiment
# (ml-training/experiments-transformers).
{
  lib,
  stdenv,
  fetchurl,
  torch-bin,
  cudaPackages,
}:

let
  version = "2.9.1";
  pyVer = "cp313";

  # Per-platform manylinux wheel tag and SRI hash, from the cu130 index at
  # https://download.pytorch.org/whl/cu130.  To bump, update `version` and run
  # `nix store prefetch-file` on the two URLs below.
  wheels = {
    aarch64-linux = {
      tag = "manylinux_2_28_aarch64";
      hash = "sha256-MrR7lRqfTo3H4TK8Li9grG3SNsV4bAcyAYW8UGLOW5I=";
    };
    x86_64-linux = {
      tag = "manylinux_2_28_x86_64";
      hash = "sha256-vew9XiakctKS7EjZ1W4/7ahvPmB0TLSckmA1Aro00zE=";
    };
  };

  system = stdenv.hostPlatform.system;
  wheelAttrs = wheels.${system} or null;

  wheel =
    if wheelAttrs == null then
      null
    else
      fetchurl {
        name = "torch-${version}+cu130-${pyVer}-${pyVer}-${wheelAttrs.tag}.whl";
        url = "https://download.pytorch.org/whl/cu130/torch-${version}%2Bcu130-${pyVer}-${pyVer}-${wheelAttrs.tag}.whl";
        inherit (wheelAttrs) hash;
      };
in
if wheelAttrs == null then
  throw "torch-cuda: unsupported system ${system} (expected aarch64-linux or x86_64-linux)"
else
  (torch-bin.override { inherit cudaPackages; }).overrideAttrs (old: {
    inherit version;
    src = wheel;
    meta = old.meta // {
      description = "PyTorch (${version}, CUDA 13.0 ${wheelAttrs.tag} wheel)";
    };
  })

# Default configuration for the astro-nix package set.
#
# This is the single place to change global build options.  `default.nix`
# imports it and merges it with the optional `config` argument, so individual
# settings can be overridden on the command line, e.g.
#
#   nix build -f . cuda-hello --arg config '{ cudaArch = [ "sm_121" ]; }'
{
  # CUDA redistributables (cudaPackages) are unfree; NixGpu and cuda-hello
  # need them.  Nothing here builds an unfree package unless asked to.
  allowUnfree = true;

  # CUDA architectures the cuda-hello test program is built for.  Each entry
  # is forwarded to nvcc: `all-major` compiles for every supported major
  # architecture, while explicit targets use the `sm_XX` spelling, e.g.
  # [ "sm_90" "sm_121" ].
  cudaArch = [ "all-major" ];
}

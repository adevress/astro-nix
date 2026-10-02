# cuda-hello — a tiny CUDA program used to exercise NixGpu.
#
# It is built with the Nix CUDA toolkit (hermetically) and links the Nix CUDA
# runtime, while at run time it needs the *host* kernel-mode driver
# (`libcuda.so.1`), which is exactly what `NixGpu` provides.
{
  lib,
  stdenv,
  cudaPackages,
  # CUDA architectures to compile for.  Each entry is either a special nvcc
  # target (`all`, `all-major`, `native`) or a real architecture (`sm_121`,
  # `sm_90a`, ...).  `all-major` covers every supported major architecture;
  # override for a specific GPU, e.g.
  #   nix build -f . cuda-hello --arg cudaArch '[ "sm_121" ]'
  cudaArch ? [ "all-major" ],
}:

let
  # Normalise "sm_121", "compute_121" or "121" to "121".
  archName = arch: lib.removePrefix "compute_" (lib.removePrefix "sm_" arch);

  # `all`/`all-major`/`native` are nvcc `-arch` keywords, while explicit
  # targets are emitted as `-gencode` entries so several can be combined in a
  # single compilation.
  cudaArchFlags = lib.concatMapStringsSep " " (
    arch:
    if
      builtins.elem arch [
        "all"
        "all-major"
        "native"
      ]
    then
      "-arch=${arch}"
    else
      "-gencode arch=compute_${archName arch},code=sm_${archName arch}"
  ) cudaArch;
in

stdenv.mkDerivation (finalAttrs: {
  pname = "cuda-hello";
  version = "1.0.0";

  src = ./.;

  dontConfigure = true;

  nativeBuildInputs = [ cudaPackages.cuda_nvcc ];
  buildInputs = [
    cudaPackages.cuda_cudart
    cudaPackages.cuda_cccl
    cudaPackages.cuda_crt
  ];

  buildPhase = ''
    runHook preBuild

    nvcc -O2 \
      ${cudaArchFlags} \
      -ccbin ${stdenv.cc}/bin \
      -I${cudaPackages.cuda_cudart}/include \
      -I${cudaPackages.cuda_cccl}/include \
      -I${cudaPackages.cuda_crt}/include \
      -L${cudaPackages.cuda_cudart}/lib \
      -Xlinker -rpath -Xlinker ${cudaPackages.cuda_cudart}/lib \
      -lcudart \
      -o cuda-hello vectorAdd.cu

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 cuda-hello "$out/bin/cuda-hello"
    runHook postInstall
  '';

  meta = {
    description = "Minimal CUDA vector-add test used to validate NixGpu";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "cuda-hello";
  };

  passthru.gpuCheck = finalAttrs.finalPackage.overrideAttrs (_: {
    requiredSystemFeatures = [ "cuda" ];
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      "$out/bin/cuda-hello"
      runHook postInstallCheck
    '';
  });
})

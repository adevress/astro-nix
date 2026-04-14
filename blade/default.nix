{
  stdenv,
  fetchFromGitHub,
  cudaPackages,
  meson,
  ninja,
  python3Packages,
  hdf5,
  pkg-config,
  lib,
}:

stdenv.mkDerivation rec {
  name = "blade";
  version = "1.0.5";

  src = fetchFromGitHub {
    owner = "luigifcruz";
    repo = "blade";
    rev = "v${version}";
    sha256 = "sha256-tZBO3WFHCv8cX7ejrhPciNLbZKq5h12HGbU/0HGBz6U=";
    fetchSubmodules = true;
  };

  patches = [ ./001-commit-id.patch ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3Packages.python
  ];

  buildInputs = [
    cudaPackages.cuda_libcufft
    cudaPackages.cuda_cudart
    cudaPackages.cuda_nvcc
    cudaPackages.cuda_nvrtc
    hdf5
  ];

  # Blade uses meson build system
  enableParallelBuilding = true;

  meta = with lib; {
    description = "Breakthrough Listen Accelerated DSP Engine - A modern, high-performance signal-processing library for radio telescopes";
    homepage = "https://github.com/luigifcruz/blade";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}

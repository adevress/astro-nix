# alea — counter based pseudo random number generators (CBRNGs)
#
# aleaWithCuda needs NIXPKGS_ALLOW_UNFREE=1 and, because the GPU tests need the
# NVIDIA driver of the machine, the sandbox turned off in /etc/nix/nix.conf:
#
#   sandbox = false     # then restart the nix daemon
#   NIXPKGS_ALLOW_UNFREE=1 nix build -f ./ aleaWithCuda
#
# --option sandbox false is not enough: a nix daemon enforces its own setting.
{
  stdenv,
  fetchgit,
  cmake,
  ninja,
  cudaPackages ? null,
  validation ? false,
  cudaArchitectures ? cudaPackages.flags.cmakeCudaArchitecturesString,
  lib,
}:

let
  doctest = fetchgit {
    url = "https://github.com/doctest/doctest.git";
    rev = "2d0a9359a60c51affe2a9bebb1be1dca47868151"; # v2.5.3
    sha256 = "sha256-+/IEISqN9HdaCJ0udLVUitOUziLvF/D3POecZMoXuho=";
  };

  random123 = fetchgit {
    url = "https://github.com/DEShawResearch/random123.git";
    rev = "726a093cd9a73f3ec3c8d7a70ff10ed8efec8d13"; # v1.14.0
    sha256 = "sha256-r69CupcUjlXSyPFvh8J9r1lalKgfc8NoRjfXMY9wmqs=";
  };

  cudaSupport = cudaPackages != null;

  cudaStdenv = cudaPackages.backendStdenv;
in
(if cudaSupport then cudaStdenv else stdenv).mkDerivation rec {
  pname = "alea";
  version = "0.1.0";

  src = fetchgit {
    url = "https://github.com/adevress/alea.git";
    rev = "d9e975de5e09d79551d5356afaf56d7614c47c06";
    sha256 = "sha256-9+q2j4TjOQ1+sZB9uUHwAxAPe8jk0O0kNlH7/8u2md8=";
    fetchSubmodules = false;
  };

  nativeBuildInputs = [
    cmake
    ninja
  ]
  ++ lib.optional cudaSupport cudaPackages.cuda_nvcc;

  buildInputs = lib.optional cudaSupport cudaPackages.cuda_cudart;

  postPatch = ''
    rm -rf third_party/doctest
    mkdir -p third_party
    ln -s ${doctest} third_party/doctest
  '';

  cmakeFlags = [
    "-DFETCHCONTENT_FULLY_DISCONNECTED=TRUE"
    "-DALEA_ENABLE_TESTS=ON"
    "-DALEA_ENABLE_INSTALL=ON"
    "-DALEA_ENABLE_BENCH=OFF"
    "-DALEA_ENABLE_CUDA=${if cudaSupport then "ON" else "OFF"}"
    "-DALEA_ENABLE_VALIDATION=${if validation then "ON" else "OFF"}"
  ]
  # must not depend on the GPU plugged into the build machine
  ++ lib.optional cudaSupport "-DCMAKE_CUDA_ARCHITECTURES=${cudaArchitectures}"
  ++ lib.optionals validation [
    "-DFETCHCONTENT_SOURCE_DIR_RANDOM123=${random123}"
  ];

  doCheck = true;

  # the nix toolchain loader only searches the store, so expose the host driver
  # through a directory holding nothing else; without it every device call
  # fails with "CUDA driver version is insufficient for CUDA runtime version"
  preCheck = lib.optionalString cudaSupport ''
    driver_dir="$PWD/.cuda-driver"
    mkdir -p "$driver_dir"
    for candidate in /usr/lib/*/libcuda.so.1 /usr/lib64/libcuda.so.1 \
                      /usr/lib/libcuda.so.1 /lib/*/libcuda.so.1 /lib64/libcuda.so.1; do
      [ -e "$candidate" ] || continue
      ln -sfn "$candidate" "$driver_dir/libcuda.so.1"
      break
    done
    if [ -e "$driver_dir/libcuda.so.1" ]; then
      export LD_LIBRARY_PATH="$driver_dir''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    elif [ -z "''${LD_LIBRARY_PATH:-}" ]; then
      echo "alea: no libcuda.so.1 found, the GPU tests need the NVIDIA driver of the machine, visible from the build (sandbox = false in nix.conf)" >&2
    fi
  '';

  meta = with lib; {
    description = "Counter based pseudo random number generators (threefry, philox, ars) in modern C++";
    homepage = "https://github.com/adevress/alea";
    license = licenses.boost;
    maintainers = with maintainers; [ ];
  };
}

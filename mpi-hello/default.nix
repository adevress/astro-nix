# mpi-hello-cpp — minimal Open MPI hello world in C++.
#
# The program is linked against the nixpkgs Open MPI build, which uses an
# external PMIx library.  That is what allows a Slurm allocation to launch it
# directly with `srun` (using Slurm's PMIx plugin) instead of mpirun/mpiexec.
{
  lib,
  stdenv,
  openmpi,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "mpi-hello-cpp";
  version = "1.0.0";

  src = ./cpp;

  dontConfigure = true;
  enableParallelBuilding = true;

  buildInputs = [ openmpi ];

  buildPhase = ''
    runHook preBuild

    ${lib.getDev openmpi}/bin/mpicxx \
      -O2 -Wall -Wextra \
      -o ${finalAttrs.pname} mpi_hello.cpp

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 ${finalAttrs.pname} "$out/bin/${finalAttrs.pname}"

    runHook postInstall
  '';

  meta = {
    description = "Minimal Open MPI hello world in C++";
    homepage = "https://github.com/adevress/astro-nix";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "mpi-hello-cpp";
  };
})

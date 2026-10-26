# mpi-hello — minimal MPI hello world using mpi4py.
#
# This lives in the Python package set so that mpi4py, Open MPI and the
# program itself share the same MPI implementation.  The console script is
# called `mpi-hello`; the C++ variant is `mpi-hello-cpp` to avoid a collision
# when both packages are present in one environment.
{
  lib,
  buildPythonApplication,
  setuptools,
  mpi4py,
}:

buildPythonApplication rec {
  pname = "mpi-hello";
  version = "1.0.0";
  pyproject = true;

  src = ./python;

  build-system = [ setuptools ];

  dependencies = [ mpi4py ];

  pythonImportsCheck = [ "mpi_hello" ];

  meta = {
    description = "Minimal MPI hello world using mpi4py";
    homepage = "https://github.com/adevress/astro-nix";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "mpi-hello";
  };
}

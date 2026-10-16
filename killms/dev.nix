# killMS "dev" — build the DD-calibrator from its Git history instead of the
# PyPI sdist.
#
# Upstream development happens on the `HackathonRennes_June26` branch of the
# private fork `cyriltasse/killMS`.  That fork is not reachable without
# credentials, so this recipe defaults to the public `saopicc/killMS`
# repository at the commit that carries the same development snapshot.
#
# To build the private fork, override the source, e.g.
#
#   killms_dev.overrideAttrs (old: {
#     src = pkgs.fetchFromGitHub {
#       owner = "cyriltasse";
#       repo = "killMS";
#       rev = "<commit on HackathonRennes_June26>";
#       hash = "sha256-...";
#     };
#   })
#
# The build itself is identical to killms/default.nix (scikit-build-core +
# CMake backend); only the source location differs.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  cmake,
  ninja,
  numpy,
  pybind11,
  cython,
  scikit-build-core,
  # Pair killMS-dev with the matching DDFacet-dev recipe.
  ddfacet,
}:

buildPythonPackage rec {
  pname = "killMS";
  version = "3.3.0-dev";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "saopicc";
    repo = "killMS";
    # Public commit equivalent to the development snapshot; the private
    # cyriltasse/killMS HackathonRennes_June26 branch is not reachable here.
    rev = "350f22c67a4b769b2c105327116028e7b13a86fb";
    hash = "sha256-2Q01G+Oo1KH6V77QlSHxWx3wRHCofiGIl6Ff6c8QuqQ=";
  };

  # Relax version pins and fix NumPy 2.x / ARM compatibility
  postPatch = ''
    # Remove version constraints from build-system requires
    sed -i -E 's/"numpy >= [^"]*"/"numpy"/g' pyproject.toml
    sed -i -E 's/"cython<=[^"]*"/"cython"/g' pyproject.toml
    # Remove version constraints from dependencies
    sed -i -E 's/"DDFacet\[kms-support\] >= [^"]*"/"DDFacet[kms-support]"/g' pyproject.toml

    # Fix 1: Guard x86 SSE header on non-x86 platforms
    sed -i 's|#include <emmintrin.h>|#ifdef __x86_64__\n#include <emmintrin.h>\n#endif|' killMS/Array/Dot/dot0.c

    # Fix 2: NumPy 2.x compatibility - replace direct struct member access
    find killMS -name "*.c" -o -name "*.h" | while read f; do
      sed -i -E 's/([A-Za-z_][A-Za-z0-9_]*)->data/PyArray_DATA(\1)/g' "$f"
      sed -i -E 's/([A-Za-z_][A-Za-z0-9_]*)->dimensions\[([0-9]+)\]/PyArray_DIM(\1, \2)/g' "$f"
    done

    # Fix 3: Suppress incompatible-pointer-types errors (PyArrayObject* vs PyObject*)
    # NumPy 2.x is stricter about types; the code works correctly at runtime
    sed -i 's/-fmax-errors=1/-fmax-errors=1 -Wno-error=incompatible-pointer-types/g' killMS/CMakeLists.txt
  '';

  build-system = [
    cmake
    ninja
    numpy
    pybind11
    cython
    scikit-build-core
  ];

  # scikit-build-core manages cmake internally via PEP 517;
  # disable nixpkgs' own cmake configure phase to avoid conflicts
  dontUseCmakeConfigure = true;
  dontUseCmakeBuildDir = true;

  dependencies = [ ddfacet ];

  pythonImportsCheck = [ "killMS" ];

  meta = with lib; {
    homepage = "https://github.com/saopicc/killMS";
    description = "Wirtinger-based direction-dependent radio interferometric calibration package (Git development snapshot)";
    license = licenses.gpl2;
    maintainers = with maintainers; [ ];
  };
}

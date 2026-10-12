# killMS 3.3.0 — Wirtinger-based direction-dependent radio interferometric calibration.
# Recompiled from the PyPI sdist (scikit-build-core + CMake backend).
{
  lib,
  buildPythonPackage,
  fetchurl,
  cmake,
  ninja,
  numpy,
  pybind11,
  cython,
  scikit-build-core,
  ddfacet,
}:

buildPythonPackage rec {
  pname = "killMS";
  version = "3.3.0";
  pyproject = true;

  src = fetchurl {
    name = "killms-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/3a/3b/3f4783828e925cef21db67b7af3b11bf5c29f392d278bf7943eb38553103/killms-${version}.tar.gz";
    sha256 = "sha256-ubHJz8ag0PNkwRYTCIMLhSGDozSSz0S3kPikwkTnRVo=";
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
    description = "Wirtinger-based direction-dependent radio interferometric calibration package";
    license = licenses.gpl2;
    maintainers = with maintainers; [ ];
  };
}

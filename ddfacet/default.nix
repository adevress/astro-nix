# DDFacet 1.0.0.0 — Facet-based radio astronomy continuum imager.
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
  setuptools,
  # Runtime dependencies
  sharedarray,
  polygon3,
  pyfftw,
  astropy,
  deap,
  ptyprocess,
  ipdb,
  python-casacore,
  pyephem,
  numexpr,
  matplotlib,
  scipy,
  psutil,
  py-cpuinfo,
  tables,
  prettytable,
  configparser,
  pandas,
  ruamel-yaml,
  pylru,
  six,
  dask,
  codex-africanus,
  regions,
  pywavelets,
  tqdm,
  pyproj,
  bdsf,
  meqtrees-cattery,
}:

buildPythonPackage rec {
  pname = "DDFacet";
  version = "1.0.0.0";
  pyproject = true;

  src = fetchurl {
    name = "ddfacet-${version}.tar.gz";
    url = "https://files.pythonhosted.org/packages/87/9f/7a29cdd2653d2ecccabb4d9fefd325e9504a00e24c60e9d75a20250013d9/ddfacet-${version}.tar.gz";
    sha256 = "sha256-P1qwkjzIhukdbTgnd5Q6yTFjOGuRZ3j3yH233O0lEb0=";
  };

  # Python 3.14 defaults to the fork-server start method, which cannot pickle
  # the psutil.Process objects held by AsyncProcessPool.  Force fork, which
  # is the semantics DDFacet was designed around.
  patches = [ ./patches/001-python314-fork-start-method.patch ];

  # Relax version pins in pyproject.toml to work with nixpkgs versions
  postPatch = ''
    python3 << 'PYEOF'
    import re
    with open('pyproject.toml', 'r') as f:
        content = f.read()
    # Remove version constraints from quoted strings in dependencies and build-system
    # Pattern: "package >= 1.0, <= 2.0" or 'package >= 1.0' -> "package" or 'package'
    # Include brackets for extras like "dask[array]" and "codex-africanus[dask]"
    content = re.sub(r'"([A-Za-z0-9_.\[\]-]+)\s*[<>=!~][^"]*"', r'"\1"', content)
    content = re.sub(r"'([A-Za-z0-9_.\[\]-]+)\s*[<>=!~][^']*'", r"'\1'", content)
    with open('pyproject.toml', 'w') as f:
        f.write(content)
    PYEOF
  '';

  build-system = [
    cmake
    ninja
    numpy
    pybind11
    cython
    scikit-build-core
    setuptools
  ];

  # scikit-build-core manages cmake internally via PEP 517;
  # disable nixpkgs' own cmake configure phase to avoid conflicts
  dontUseCmakeConfigure = true;
  dontUseCmakeBuildDir = true;

  dependencies = [
    cython
    numpy
    sharedarray
    polygon3
    pyfftw
    astropy
    deap
    ptyprocess
    ipdb
    python-casacore
    pyephem
    numexpr
    matplotlib
    scipy
    psutil
    py-cpuinfo
    tables
    prettytable
    pybind11
    configparser
    pandas
    ruamel-yaml
    pylru
    six
    dask
    codex-africanus
    regions
    pywavelets
    tqdm
    pyproj
    # Optional extras
    bdsf # kms-support
    meqtrees-cattery # fits-beam-support
  ];

  pythonImportsCheck = [ "DDFacet" ];

  meta = with lib; {
    homepage = "https://github.com/saopicc/DDFacet";
    description = "Facet-based radio astronomy continuum imager";
    license = licenses.gpl2;
    maintainers = with maintainers; [ ];
  };
}

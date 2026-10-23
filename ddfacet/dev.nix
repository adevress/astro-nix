# DDFacet "dev" — build the imager from the private development fork.
#
# Upstream development happens on the `HackathonRennes_June26_Adastra` branch
# of the private fork `cyriltasse/DDFacet`.  The source is fetched with
# `builtins.fetchGit` over SSH, so GitHub credentials (and network access) are
# required at evaluation time.  The commit is pinned by `rev`.
#
# The build itself is identical to ddfacet/default.nix (scikit-build-core +
# CMake backend); only the source location differs.
{
  lib,
  buildPythonPackage,
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
  zarr,
  xarray,
  mpi4py,
  fasteners,
  lofarbeam,
}:

buildPythonPackage rec {
  pname = "DDFacet";
  version = "0.9.1.0";
  pyproject = true;

  src = builtins.fetchGit {
    url = "ssh://git@github.com/cyriltasse/DDFacet";
    ref = "refs/heads/HackathonRennes_June26_Adastra";
    rev = "e8dce1e0c68e05c49cea3bfe874375680a703036";
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
    # Upstream does not declare lofarbeam (provided by the astro-nix `lofarbeam`
    # package) in its project dependencies: add it.
    content, n = re.subn(r'(^dependencies\s*=\s*\[\n)', r'\1    "lofarbeam",\n', content, count=1, flags=re.MULTILINE)
    assert n == 1, "could not find the dependencies list in pyproject.toml"
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
    zarr
    xarray
    mpi4py
    fasteners
    lofarbeam
  ];

  pythonImportsCheck = [ "DDFacet" ];

  meta = with lib; {
    homepage = "https://github.com/saopicc/DDFacet";
    description = "Facet-based radio astronomy continuum imager (Git development snapshot)";
    license = licenses.gpl2;
    maintainers = with maintainers; [ ];
  };
}

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
  #
  # 002: NumPy >= 2.4 refuses to assign a 1-element array to a scalar slot
  # (ClusterCat.ra[i] = lm2radec(...)), which broke ClusterCat.py.
  # 003: Python 2 leftovers (tuple parameters, `except E,e`, empty function body) that fail
  # to byte-compile on Python 3.
  # 004: re.sub(..., count) positional use is deprecated since Python 3.13 and
  # DDF.py turns that warning into an error, breaking the log formatter.
  patches = [
    ./patches/001-python314-fork-start-method.patch
    ./patches/002-numpy-scalar-assignment.patch
    ./patches/003-python3-syntax.patch
    ./patches/004-re-sub-count-keyword.patch
  ];

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
    # Upstream ships DDFacet.__main__:iomonitor_main (and IOMonitor.driver) but
    # forgets to declare the IOMonitor.py console script: add it.
    if "iomonitor_main" not in content:
        content, n = re.subn(r'(^\[project\.scripts\]\n)', r'\1"IOMonitor.py" = "DDFacet.__main__:iomonitor_main"\n', content, count=1, flags=re.MULTILINE)
        assert n == 1, "could not find [project.scripts] in pyproject.toml"
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

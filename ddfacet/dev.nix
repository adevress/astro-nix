# DDFacet "dev" — build the imager from its Git history instead of the PyPI
# sdist.
#
# Upstream development happens on the `HackathonRennes_June26` branch of the
# private fork `cyriltasse/DDFacet`.  That fork is not reachable without
# credentials, so this recipe defaults to the public `saopicc/DDFacet`
# repository at the commit that carries the same development snapshot.
#
# To build the private fork, override the source, e.g.
#
#   ddfacet_dev.overrideAttrs (old: {
#     src = pkgs.fetchFromGitHub {
#       owner = "cyriltasse";
#       repo = "DDFacet";
#       rev = "<commit on HackathonRennes_June26>";
#       hash = "sha256-...";
#     };
#   })
#
# The build itself is identical to ddfacet/default.nix (scikit-build-core +
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
  mpi4py
}:

buildPythonPackage rec {
  pname = "DDFacet-dev";
  version = "1.0.0.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "saopicc";
    repo = "DDFacet";
    # Public commit equivalent to the development snapshot; the private
    # cyriltasse/DDFacet HackathonRennes_June26 branch is not reachable here.
    rev = "2fe05ab4a3399ef44a631b6116608f21239e2a57";
    hash = "sha256-JwiiIzPdNg8pQMu+C1exyU1xmo/R9q2QjtV+kjRhiPs=";
  };

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
    zarr
    xarray
    mpi4py
  ];

  pythonImportsCheck = [ "DDFacet" ];

  meta = with lib; {
    homepage = "https://github.com/saopicc/DDFacet";
    description = "Facet-based radio astronomy continuum imager (Git development snapshot)";
    license = licenses.gpl2;
    maintainers = with maintainers; [ ];
  };
}

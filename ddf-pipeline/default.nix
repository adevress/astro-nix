# ddf-pipeline — LOFAR pipeline using killms/ddfacet.
# From the HackathonRennes_June26 branch of mhardcastle/ddf-pipeline.
{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  editables,
  # Runtime dependencies
  ddfacet,
  killms,
  astropy,
  astropy-iers-data,
  numpy,
  scipy,
  psutil,
  bcrypt,
  cffi,
  cryptography,
  paramiko,
  pycparser,
  pyerfa,
  pymysql,
  pynacl,
  pyparsing,
  python-casacore,
  pyyaml,
  pyregion,
  sshtunnel,
  treepick,
  yorn,
  pdu,
  emcee,
  packaging,
  six,
  mpi4py
}:

buildPythonPackage rec {
  pname = "ddf-pipeline";
  version = "0.1.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "mhardcastle";
    repo = "ddf-pipeline";
    rev = "2a7648d2ac866f69f9a25eed1d64b73bc2b25589"; # HackathonRennes_June26 branch HEAD
    sha256 = "sha256-vHdb0nY6IuF809FC4MeuHthnM7k1rNqC+C/y8FLWp/w=";
  };

  # Relax version pins and remove unavailable deps from pyproject.toml
  postPatch = ''
    python3 << 'PYEOF'
    import re
    with open('pyproject.toml', 'r') as f:
        content = f.read()
    # Remove version constraints: "package==1.0" -> "package"
    content = re.sub(r'"([A-Za-z0-9_.\[\]-]+)==[^"]*"', r'"\1"', content)
    # Remove packages not available in nixpkgs: future (Python 3.13 incompatible), everybeam
    lines = content.split('\n')
    filtered = []
    for line in lines:
        stripped = line.strip()
        # Skip lines that are just "future" or "everybeam" dependencies
        if stripped in ['"future",', '"future"', '"everybeam",', '"everybeam"']:
            continue
        # Skip duplicate python-casacore (keep only the first)
        if '"python-casacore"' in stripped and '# lofar' in stripped:
            continue
        filtered.append(line)
    content = '\n'.join(filtered)
    # Fix the numpy comment line
    content = content.replace('"numpy", #==2.2.6",', '"numpy",')
    with open('pyproject.toml', 'w') as f:
        f.write(content)
    PYEOF

    # Remove 'future'/'past' package imports (Python 2/3 compat, not needed on Python 3.13)
    # Replace "from past.utils import old_div" with a no-op (old_div is just / on Python 3)
    # Replace "from future import standard_library" and "from future.utils import ..." with no-ops
    find . -name "*.py" -exec sed -i \
      -e 's/from past.utils import old_div/old_div = lambda a, b: a \/ b  # Python 3 true division/' \
      -e '/from future import standard_library/d' \
      -e '/from future.utils import/d' \
      -e '/standard_library.install_aliases()/d' \
      -e 's/from builtins import zip/from builtins import zip  # future compat/' \
      -e 's/from builtins import str/from builtins import str  # future compat/' \
      -e 's/from builtins import range/from builtins import range  # future compat/' \
      {} +

    # Fix sys.path to include utils/ and others/ directories for top-level imports
    sed -i "s|sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))|sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))\nsys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'utils')))\nsys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'others')))|" scripts/pipeline.py
  '';

  build-system = [
    hatchling
    editables
  ];

  dependencies = [
    ddfacet
    killms
    astropy
    astropy-iers-data
    numpy
    scipy
    psutil
    bcrypt
    cffi
    cryptography
    paramiko
    pycparser
    pyerfa
    pymysql
    pynacl
    pyparsing
    python-casacore
    pyyaml
    pyregion
    sshtunnel
    treepick
    yorn
    pdu
    emcee
    packaging
    six
    mpi4py
  ];

  pythonImportsCheck = [
    "scripts"
    "utils"
  ];

  meta = with lib; {
    homepage = "https://github.com/mhardcastle/ddf-pipeline";
    description = "LOFAR pipeline using killms/ddfacet for direction-dependent self-calibration";
    license = licenses.gpl2;
    maintainers = with maintainers; [ ];
  };
}

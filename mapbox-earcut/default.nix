# mapbox-earcut 2.0.0 — Python polygon triangulation bindings.
#
# Used by CyberEther at build time (resources/geodata: parser.py triangulates
# world GeoJSON -> geodata.hh) and optionally at runtime by Superluminal.
# scikit-build-core wheel over nanobind (same stack as nixpkgs `nanobind`).
{
  lib,
  buildPythonPackage,
  fetchurl,
  cmake,
  ninja,
  pathspec,
  scikit-build-core,
  nanobind,
  numpy,
}:

buildPythonPackage rec {
  pname = "mapbox-earcut";
  version = "2.0.0";
  pyproject = true;

  src = fetchurl {
    name = "mapbox_earcut-2.0.0.tar.gz";
    url = "https://files.pythonhosted.org/packages/source/m/mapbox-earcut/mapbox_earcut-2.0.0.tar.gz";
    sha256 = "sha256-geq2uGz5lVHetpi5jj91AsV5AOXEed8V4b2vGlfw+dY=";
  };

  # nixpkgs-25.11 ships scikit-build-core 0.11.5; the sdist pins >=0.11.6.
  # Relax the build-system pin to the packaged version (behavioural no-op).
  postPatch = ''
    sed -i 's/scikit-build-core>=0.11.6/scikit-build-core>=0.11.5/' pyproject.toml
  '';

  build-system = [
    cmake
    ninja
    pathspec
    scikit-build-core
    nanobind
  ];

  dependencies = [ numpy ];

  # scikit-build-core + nixpkgs cmake builder both default to a `build/` dir;
  # same fix as nixpkgs' nanobind recipe.
  dontUseCmakeBuildDir = true;

  pythonImportsCheck = [ "mapbox_earcut" ];

  meta = with lib; {
    homepage = "https://github.com/skogler/mapbox_earcut_python";
    description = "Python bindings for the mapbox earcut C++ polygon triangulation library";
    license = licenses.isc;
    maintainers = with maintainers; [ ];
  };
}

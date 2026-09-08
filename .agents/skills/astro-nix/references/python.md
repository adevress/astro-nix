# Python environments

Upstream: `nixos.org/manual/nixpkgs/stable/#python`. Rule: never
`nix-env -i` Python libs — wrap the interpreter so modules find each other.

## The repo env: `astroPyEnv`

Defined in `default.nix:py_astro_pkgs`:

```nix
astroPyEnv = pkgs.python3Packages.python.withPackages (ps: [
  python3Packages.radler   # Radler Python bindings
  ps.scipy ps.numpy ps.dask ps.xarray ps.matplotlib ps.astropy
]);
```

Use it:

```bash
nix shell -f ./ astroPyEnv --command bash
python -c "import astropy, radler; print('Success!')"
```

## Ad-hoc envs (`withPackages` / `buildEnv`)

```bash
# throwaway shell with numpy+toolz (upstream pattern):
nix-shell -p 'python313.withPackages (ps: with ps; [numpy toolz])'
# run directly:
nix-shell -p 'python313.withPackages (ps: with ps; [numpy toolz requests])' --run python3
```

`python.withPackages (ps: [...])` is sugar over `python.buildEnv.override`.
`ps` is the package set matching the interpreter (`python3Packages` for
`python3`). Module names follow PEP 503 (`Foo__Bar.baz` → `foo-bar-baz`).
Need `ignoreCollisions`/`postBuild`? Drop to `python.buildEnv.override
{ extraLibs = [...]; ignoreCollisions = true; }`. Need `.env` shell form?
Append `.env`: `(python3.withPackages (ps: [...])).env`.

Shebang form for scripts: `#!/usr/bin/env nix-shell -i python3 -p "python3.withPackages(ps: [ps.numpy])"`.

## Packaging a Python lib (`buildPythonPackage`)

Pattern (see `radler/default.nix` with `pythonBuild` flag):

```nix
{ buildPythonPackage, fetchPypi, setuptools, ... }:
buildPythonPackage {
  pname = "foo"; version = "1.0.0"; pyproject = true;
  src = fetchPypi { inherit pname version; hash = "sha256-..."; };
  build-system = [ setuptools ];
  dependencies = [ ... ];
  nativeCheckInputs = [ pytestCheckHook ];
  pythonImportsCheck = [ "foo" ];
}
```

In this repo Python packages join the interpreter's set, e.g.:

```nix
python3Packages = pkgs.python3Packages // {
  radler = astro_pkgs.radler.override { pythonBuild = true; };
  xtensor-python = pkgs.callPackage ./xtensor-python/default.nix { };
};
```

Then include them in `withPackages (ps: [ ... ])` like any `ps.*` lib.

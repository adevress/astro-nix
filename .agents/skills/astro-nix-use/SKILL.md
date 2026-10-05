---
name: astro-nix-use
description: Search, list, install, run, and compose radio-astronomy / radio-interferometry software with the astro-nix Nix package collection (wsclean, casacore, radler, idg, everybeam, dysco, aoflagger, oskar, ds9, astroPyEnv). Covers nix shell/run/build/profile, shell.nix and default.nix, callPackage-based derivation composition, python3.withPackages environments, and binary-cache or rootless/HPC troubleshooting. Use when setting up, editing, or debugging astro-nix packages, Nix environments, shell.nix, or custom derivations.
compatibility: Requires the nix CLI (>= 2.x) with nix-command enabled. Works with root or rootless Nix installs on Linux x86_64 and aarch64.
---

# astro-nix-use

How to use the astro-nix repository (a collection of Nix recipes for radio astronomy) to search, list, inspect, install, run, and compose packages into reproducible environments. It also covers the two most common tasks beyond "install a package": composing custom derivations and building Python environments.

## Prerequisites

1. Clone the astro-nix repository and run all `-f ./` commands from its root.
2. Nix must be installed.
   - With root: daemon install (`sh <(curl ...) --daemon`), then `sudo ./scripts/nix-command-edit.sh`, then restart `nix-daemon`.
   - Without root (HPC): follow `doc/rootless-nix.md` in the repo.
3. Enable the binary cache, otherwise packages compile from source. The setup scripts write this to `nix.conf`:

   ```
   extra-experimental-features = nix-command flakes
   extra-substituters = https://cache.astro-nix.space/
   extra-trusted-public-keys = astro-nix-secret:QASg0gb6rH/PxxthSsoGvw739dyKwEIVnhhhD7wA02A=
   ```

   Values live in `config/nix-cache.source`; rootless config is in `doc/rootless-nix.md`.

## Mental model

- `default.nix` at the repo root pins nixpkgs (currently release 25.11) and returns a function. Calling it merges **all of nixpkgs** with the astro packages:

  ```nix
  # default.nix
  { upstream_pkgs ? pkgs }:
  pkgs // astro_pkgs // py_astro_pkgs
  ```

  In practice that means `import ./default.nix {}` is one big package set, and `nix <cmd> -f ./ <attr>` works both for upstream nixpkgs (`python3`, `cmake`) and for astro packages (`wsclean`, `casacore`).

- Each astro package is a folder with a `default.nix` recipe (e.g. `wsclean/default.nix`). The root `default.nix` wires dependencies between those recipes.
- The package list and dependency graph are in [references/packages.md](references/packages.md). A ready-made shell template is at [assets/shell.nix](assets/shell.nix).

## 1. Searching and listing packages

To search information about a package, Use: 

`nix search . <package name>`

NOTE: You can replace the '.' by the location of the astro-nix git repository

To search exlusively in the nixpkgs upstream, Use:

`nix search nixpkgs <package name>`

To List all packages available, Use:

`nix search . ".*"`

NOTE: This can take a significant amount of time

## 2. Inspecting a package

To find a read-only recipe of a software, Use:

`nix eval --raw .#<package name>.meta.position`

NOTE: Replace the "." by the location of the astro-nix git repository

## 3. Installing / running

```bash
nix shell -f ./ wsclean --command bash   # ephemeral shell with wsclean on PATH (most common)
nix shell -f ./ casacore --command bash  # then run e.g. readms, taql
nix run -f ./ ds9                        # run a binary directly (short-lived app)
nix run -f ./ hello                      # smoke-test the setup
nix build -f ./ wsclean                  # build and symlink ./result
nix profile install -f ./ wsclean        # persistent install into the user profile
nix profile list                         # list profile packages
```

For a package that exposes several binaries (`casacore`, `wcstools`), prefer `nix shell ... --command bash` and then run the binary by name. `nix run` is best for single-command tools such as `ds9`.

## 4. Composing environments

Ad-hoc (several packages in one ephemeral shell):

```bash
nix shell -f ./ wsclean aoflagger dysco casacore python3 --command bash
```

Declarative (preferred for projects): create a `shell.nix`:

```nix
let
  # Pin a specific astro-nix revision for reproducibility:
  # astro = import (fetchTarball {
  #   url = "https://github.com/adevress/astro-nix/archive/<rev>.tar.gz";
  #   sha256 = "<sha256>";
  # }) {};
  astro = import /path/to/astro-nix {};
in
astro.mkShell {
  packages = with astro; [
    casacore
    dysco
    aoflagger
    wsclean
    everybeam
    ds9
  ];
}
```

```bash
nix-shell   # enter the environment described by shell.nix
```

A more complete template, including a Python stack, is at [assets/shell.nix](assets/shell.nix).

## 5. Python environments

The repo already ships a ready-made Python environment:

```bash
nix shell -f ./ astroPyEnv --command python -c "import astropy; print('ok')"
```

`astroPyEnv` contains: python3, astropy, radler python bindings, numpy, scipy, dask, xarray, matplotlib.

To create a custom Python environment, use `python3.withPackages`. The astro-specific Python package set is exposed as `python3Packages` (it is `pkgs.python3Packages` extended with astro bindings):

```nix
let
  astro = import /path/to/astro-nix {};
  myPython = astro.python3Packages.python.withPackages (ps: [
    astro.python3Packages.radler  # radler with pythonBuild = true
    ps.astropy
    ps.numpy
    ps.scipy
    ps.matplotlib
    ps.dask
    ps.xarray
  ]);
in
astro.mkShell {
  packages = [ myPython astro.wsclean astro.ds9 ];
}
```

Why this works:

- The root `default.nix` defines `python3Packages = pkgs.python3Packages // rec { radler = astro_pkgs.radler.override { pythonBuild = true; }; ... }`.
- `python3.withPackages` takes a function from a Python package set (`ps`) to a list of packages, and returns a Python interpreter that has exactly those packages importable.
- The `radler` package is a C++ CMake project. Its recipe (`radler/default.nix`) switches between `stdenv.mkDerivation` and `python3Packages.buildPythonPackage` based on `pythonBuild ? false`. That is why the Python bindings are built from the same source via an override rather than a separate recipe.

## 6. Derivation composition basics

### 6.1 Anatomy of a recipe

A recipe is a function from dependency attributes to a derivation. Example `hello/default.nix`:

```nix
{ stdenv }:

stdenv.mkDerivation {
  name = "hello";
  src = ./.;
  buildPhase = ''
    ${stdenv.cc}/bin/gcc -o hello hello.c
  '';
  installPhase = ''
    mkdir -p $out/bin
    cp hello $out/bin
  '';
}
```

`pkgs.callPackage ./hello/default.nix { }` does two things:

1. Calls the function with every matching nixpkgs attribute (`stdenv`, `cmake`, `boost`, ...) automatically.
2. Lets the caller override or add dependencies explicitly.

That is the composition mechanism used throughout the repo.

### 6.2 How the root default.nix composes packages

From the root `default.nix`:

```nix
openblasSingleThreaded = pkgs.openblas.override { singleThreaded = true; };

casacore = pkgs.callPackage ./casacore/default.nix {
  openblas = openblasSingleThreaded;
  inherit wcslib;
};

aocommon = pkgs.callPackage ./aocommon/default.nix {
  openblas = openblasSingleThreaded;
  inherit casacore;
};

wsclean = pkgs.callPackage ./wsclean/default.nix {
  inherit aocommon radler schaapcommon idg;
  ska-sdp-func = null;
};
```

Patterns to learn:

- `callPackage ./folder/default.nix { }` — auto-wires all function arguments from nixpkgs.
- `callPackage ./folder/default.nix { dep = ...; }` — explicitly sets a dependency, overriding the nixpkgs default.
- `inherit foo bar;` — shorthand for `foo = foo; bar = bar;`.
- `.override { ... }` — reuses an existing derivation with changed arguments (e.g. `openblas` single-threaded, or `radler.override { pythonBuild = true; }`).
- Optional dependencies are expressed with default `null` arguments in the recipe, and conditionals in the recipe body (`lib.optionals (ska-sdp-func != null) [ ... ]` in `wsclean/default.nix`).

### 6.3 Adding a new package

Create `mypkg/default.nix`:

```nix
{
  stdenv,
  cmake,
  casacore,
  lib,
}:

stdenv.mkDerivation rec {
  pname = "mypkg";
  version = "0.1.0";

  src = ./.; # local source; for remote sources use fetchurl / fetchgit / fetchFromGitHub

  nativeBuildInputs = [ cmake ];
  buildInputs = [ casacore ];

  cmakeFlags = [ "-DPORTABLE=ON" ];

  meta = with lib; {
    description = "My radio-astronomy tool";
    license = licenses.gpl3;
  };
}
```

Then wire it in the root `default.nix`:

```nix
mypkg = pkgs.callPackage ./mypkg/default.nix {
  inherit casacore;
};
```

Build and run:

```bash
nix build -f ./ mypkg
nix shell -f ./ mypkg --command bash
```

### 6.4 Python recipe composition

For pure-Python or pybind packages, prefer `python3Packages.buildPythonPackage`; the result is already importable by `python3.withPackages`. If you must wrap a plain `stdenv.mkDerivation` that installs a Python package layout, use `python3Packages.toPythonModule` (see `xtensor-python/default.nix`). For C++ packages with optional Python bindings, the `radler` pattern is the reference: one source, one recipe, and a boolean parameter that selects the builder.

## 7. Key recipes and patterns

- **`astroPyEnv`** — ready-made Python env. Use directly or copy its `withPackages` pattern from root `default.nix`.
- **Python bindings for a C++ package** — `python3Packages.radler` is the ready-made binding; the same source can also produce the C++ library (`radler`) via the `pythonBuild ? false` switch in `radler/default.nix`.
- **Variants** — `oskarWithGUI` (`pkgs.libsForQt5.callPackage ./oskar/default.nix { withGUI = true; ... }`), `openblasSingleThreaded` (`pkgs.openblas.override { singleThreaded = true; }`).
- **Optional features** — `wsclean` takes `ska-sdp-func = null` by default; enable it with `wsclean.override { ska-sdp-func = astro.ska-sdp-func; }`.
- **Vendored submodules removed** — `wsclean`, `aoflagger`, `idg`, `everybeam` delete vendored submodules in `postPatch` and symlink the astro-nix packaged versions; keep those versions consistent when editing recipes.

## 8. Troubleshooting

- **Long compile times** — the binary cache is not enabled or trusted. Check `nix.conf` (see Prerequisites), then confirm a cached path exists: `nix path-info -f ./ <pkg>`.
- **`experimental Nix feature 'nix-command' is disabled`** — add `extra-experimental-features = nix-command flakes` to `nix.conf`, or pass `--extra-experimental-features 'nix-command flakes'`.
- **`nix search -f ./` errors / evaluating entire nixpkgs** — this repo is not a flake and its merged set is the entire nixpkgs tree; use the `nix eval` listing commands from section 1 instead of `nix search -f ./`.
- **Rootless/HPC** — set `store`, `ssl-cert-file`, and `ignored-acls = lustre.lov` as in `doc/rootless-nix.md`; avoid NFS store locations.
- **Pin for reproducibility** — reference astro-nix via `fetchTarball` with a sha256 (or `builtins.fetchGit` with a revision) in your `shell.nix`, so all machines resolve the identical source tree and share cache paths.

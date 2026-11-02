---
name: astro-nix-use
description: Search, list, install, run, and compose radio-astronomy / radio-interferometry software from the astro-nix Nix package collection (wsclean, casacore, radler, idg, everybeam, dysco, aoflagger, oskar, ds9, astroPyEnv, ddfPyEnv, dp3, mpi-hello-cpp, mpi4py, ...). Works straight from the GitHub tarball URL — no local clone needed — and equally from a local clone, via the <astro_nix> pointer used in every command. Covers nix shell/run/build/profile, nix search, shell.nix and flake composition, callPackage-based derivation wiring, python3.withPackages environments, Open MPI/Slurm PMIx, and binary-cache / rootless / HPC setup. Use when setting up, editing, or debugging astro-nix packages, Nix environments, or custom derivations.
compatibility: Requires the Nix CLI (>= 2.x) with the `nix-command` and `flakes` experimental features enabled (see Setup). Works root or rootless on Linux x86_64 and aarch64. No git clone of astro-nix is required — the default <astro_nix> value is the GitHub tarball URL.
---

# astro-nix-use

astro-nix is a collection of Nix recipes for astronomy & radio astronomy
(`https://github.com/adevress/astro-nix`). This skill shows how to search, inspect,
install, run, and compose its packages.

## 0. The `<astro_nix>` pointer — read this first

Every command in this skill contains the token **`<astro_nix>`**. Replace that token
(including the angle brackets) with exactly **one** of:

```bash
# (a) Default — the upstream GitHub tarball. No clone needed; Nix downloads and
#     caches it on first use:
<astro_nix> = https://github.com/adevress/astro-nix/archive/refs/heads/main.tar.gz

# (b) A local git clone of the repo (use this when you edit recipes locally —
#     changes are invisible through the tarball URL):
<astro_nix> = /path/to/astro-nix
```

Both forms work everywhere in this skill:

- `nix <cmd> -f <astro_nix> <attr>` accepts both a URL and a local path.
- `nix search <astro_nix> ...` treats `<astro_nix>` as a flake reference; this works
  with the tarball URL and with a local path because the repo ships a `flake.nix`.

For reproducibility, pin a commit instead of `main`:
`https://github.com/adevress/astro-nix/archive/<full-sha>.tar.gz`
(or the flake ref `github:adevress/astro-nix/<sha>`).

Example of the substitution — the command:

```bash
nix shell -f <astro_nix> wsclean --command bash
```

becomes, with the default tarball:

```bash
nix shell -f https://github.com/adevress/astro-nix/archive/refs/heads/main.tar.gz wsclean --command bash
```

or, with a local clone:

```bash
nix shell -f /path/to/astro-nix wsclean --command bash
```

## Setup (one-time, no clone needed)

1. Install Nix. With root: `sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --daemon`.
   Without root (HPC): follow the rootless walkthrough in §8.
2. Enable the experimental features and the astro-nix binary cache in
   `/etc/nix/nix.conf` (root) or `~/.config/nix/nix.conf` (rootless):

   ```
   extra-experimental-features = nix-command flakes
   extra-substituters = https://cache.astro-nix.space/
   extra-trusted-public-keys = astro-nix-secret:QASg0gb6rH/PxxthSsoGvw739dyKwEIVnhhhD7wA02A=
   ```

   (With a root install *and* a local clone, `sudo ./scripts/nix-command-edit.sh`
   writes these lines for you.)
3. Sanity check: `nix --version` and `nix show-config | grep -E 'experimental-features|substituters'`.

## Mental model

- Repo layout: `default.nix` is the entry point — it pins nixpkgs **release 25.11**
  (via `fetchTarball`), accepts optional `system` and `config` arguments, and
  delegates to **`all_packages.nix`**, which builds the actual package set with
  `lib.makeScope` and is where all packages are wired together. Each package is a
  folder with its own `default.nix` recipe. A `flake.nix` exposes the same set as
  `legacyPackages.<system>` plus an overlay (`astroPkgs`).
- `nix <cmd> -f <astro_nix> <attr>` evaluates the astro-nix package set. It contains
  **astro-nix's own packages only** — upstream nixpkgs tools (`python3`, `cmake`,
  `git`, ...) are *not* in it. Get those from the `nixpkgs` flake ref
  (`nix shell nixpkgs#python3 ...`); for Python work use `astroPyEnv`.
- `nix search <astro_nix> <regex>` searches the astro-nix attributes (via the flake).
  `nix search nixpkgs <regex>` searches upstream nixpkgs — note the registry's
  nixpkgs may differ from astro-nix's pinned 25.11.
- Package list and dependency graph: [references/packages.md](references/packages.md).
  Ready-made shell template: [assets/shell.nix](assets/shell.nix). Source of truth
  for wiring: `all_packages.nix`.

## 1. Searching and listing packages

```bash
nix search <astro_nix> wsclean                          # search astro-nix packages
nix search <astro_nix> 'wsclean|casacore|aoflagger'     # regex is supported
nix search nixpkgs python3                              # search upstream nixpkgs
nix eval -f <astro_nix> --apply 'f: builtins.attrNames (f {})' --json   # list all astro attrs (fast)
```

`nix search <astro_nix> ".*"` lists everything but walks the whole set — prefer the
`attrNames` one-liner above or [references/packages.md](references/packages.md).

## 2. Inspecting a package

```bash
nix eval -f <astro_nix> --raw wsclean.meta.position      # recipe file:line
nix eval -f <astro_nix> --raw wsclean.version
nix eval -f <astro_nix> --raw wsclean.meta.description
nix eval -f <astro_nix> --raw wsclean.drvPath
```

## 3. Installing / running

```bash
nix shell -f <astro_nix> wsclean --command bash     # ephemeral shell (most common)
nix shell -f <astro_nix> wsclean aoflagger dysco casacore --command bash
nix shell -f <astro_nix> astroPyEnv --command python -c "import astropy; print('ok')"
nix run -f <astro_nix> ds9                         # single-binary app
nix run -f <astro_nix> hello                        # smoke-test the setup
nix build -f <astro_nix> wsclean                    # build and symlink ./result
nix profile install -f <astro_nix> wsclean          # persistent install
nix profile list                                     # list profile packages
```

Notes:

- Packages exposing several binaries (`casacore` → `readms`, `taql`; `wcstools`):
  prefer `nix shell ... --command bash`, then call the binary by name. `nix run` is
  best for single-command tools (`ds9`, `hello`, `mpi-hello-cpp`).
- Mix astro-nix packages with upstream nixpkgs tools (flake-style refs):
  `nix shell "<astro_nix>#wsclean" nixpkgs#python3 --command bash`
- Build configuration can be overridden per invocation (see §6.3):
  `nix build -f <astro_nix> cuda-hello --arg config '{ cudaArch = [ "sm_90" ]; }'`

## 4. Composing environments

Ad-hoc (several packages in one ephemeral shell):

```bash
nix shell -f <astro_nix> wsclean everybeam aoflagger astroPyEnv --command bash
```

Declarative `shell.nix` (ready-made template: [assets/shell.nix](assets/shell.nix)):
the template's `astroSrc` binding **is** the `<astro_nix>` pointer — it defaults to
the tarball URL; replace it with a local clone path to use your checkout. Then enter
with plain `nix-shell`.

Flake-based project (recommended when you want reproducible, shareable environments):

```nix
{
  inputs.astro-nix.url = "github:adevress/astro-nix";      # pin: github:adevress/astro-nix/<sha>
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11"; # match astro-nix's pin
  outputs = { nixpkgs, astro-nix, ... }:
    let
      pkgs = import nixpkgs {
        overlays = [ astro-nix.overlays.default ];  # exposes pkgs.astroPkgs.*
      };
    in {
      # devShells.<system>.default = pkgs.mkShell { packages = [ pkgs.astroPkgs.wsclean ... ]; };
    };
}
```

With the overlay, astro packages land in `pkgs.astroPkgs.*` and mix freely with
upstream `pkgs.*` inside `pkgs.mkShell`. Ad-hoc flake-style equivalent:
`nix shell "github:adevress/astro-nix#wsclean" --command bash`.

## 5. Python environments

The repo ships ready-made environments:

```bash
nix shell -f <astro_nix> astroPyEnv --command python -c "import astropy, radler; print('ok')"
nix shell -f <astro_nix> ddfPyEnv --command bash    # full DDF pipeline stack (ddfPyEnvDev = git variant)
```

`astroPyEnv` = python3 + radler Python bindings + astropy, numpy, scipy, dask,
xarray, matplotlib, mapbox-earcut.

For a custom environment, use `python3.withPackages`. The astro set's
`python3Packages` is `pkgs.python3Packages.overrideScope ...` (defined in
`all_packages.nix`) extended with the astro bindings:

```nix
let
  # <astro_nix> as a Nix value: tarball URL (default)...
  astro = import (builtins.fetchTarball
    "https://github.com/adevress/astro-nix/archive/refs/heads/main.tar.gz") { };
  # ...or, for a local clone, replace the line above with:
  # astro = import /path/to/astro-nix { };
  myPython = astro.python3Packages.python.withPackages (ps: [
    ps.radler            # radler built with pythonBuild = true
    ps.xtensor-python
    ps.astropy ps.numpy ps.scipy ps.matplotlib ps.dask ps.xarray
  ]);
in
myPython
```

Why this works: the `radler` package is a C++ CMake project whose recipe
(`radler/default.nix`) selects the builder via `pythonBuild ? false`
(`stdenv.mkDerivation` vs `python3Packages.buildPythonPackage`), so the Python
bindings are the same source built through an override, not a separate recipe.

## 6. Derivation composition basics

### 6.1 Anatomy of a recipe

A recipe is a function from dependency attributes to a derivation. Example
`hello/default.nix`:

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

`callPackage ./hello/default.nix { }` does two things:

1. Calls the function with every matching attribute (`stdenv`, `cmake`, `boost`, ...)
   automatically.
2. Lets the caller override or add dependencies explicitly.

That is the composition mechanism used throughout the repo.

### 6.2 Where packages are wired: `all_packages.nix`

The wiring lives in **`all_packages.nix`** (not in the root `default.nix`, which only
pins nixpkgs and imports it):

```nix
openblasSingleThreaded = pkgs.openblas.override {
  singleThreaded = true;
  blas64 = false;   # LP64: casacore/aocommon/DP3 pass 32-bit int to BLAS
};

casacore = callPackage ./casacore/default.nix {
  openblas = openblasSingleThreaded;
  inherit wcslib;
};

aocommon = callPackage ./aocommon/default.nix {
  openblas = openblasSingleThreaded;
  inherit casacore;
};

wsclean = callPackage ./wsclean/default.nix {
  inherit aocommon radler schaapcommon idg;
  ska-sdp-func = null;   # optional dependency
};
```

Patterns to learn:

- `callPackage ./folder/default.nix { }` — auto-wire all function arguments.
- `callPackage ./folder/default.nix { dep = ...; }` — explicitly set a dependency,
  overriding the default.
- `inherit foo bar;` — shorthand for `foo = foo; bar = bar;`.
- `.override { ... }` — reuse a derivation with changed arguments (e.g. `openblas`
  single-threaded, or `radler.override { pythonBuild = true; }`).
- Optional dependencies are default-`null` arguments in the recipe, consumed with
  conditionals in the recipe body (`lib.optionals (ska-sdp-func != null) [ ... ]`).

### 6.3 Adding a new package (requires a local clone)

Editing recipes only makes sense with a local checkout — use
`<astro_nix> = /path/to/astro-nix` in all commands of this section, because the
tarball URL will not contain your changes.

1. Create `mypkg/default.nix`:

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

     src = ./.; # local source; for remote sources use fetchurl / fetchFromGitHub

     nativeBuildInputs = [ cmake ];
     buildInputs = [ casacore ];

     cmakeFlags = [ "-DPORTABLE=ON" ];

     meta = with lib; {
       description = "My radio-astronomy tool";
       homepage = "https://example.org/mypkg";
       license = licenses.gpl3;
       maintainers = [ lib.maintainers.you ];
     };
   }
   ```

2. Wire it in **`all_packages.nix`**: `mypkg = callPackage ./mypkg/default.nix { inherit casacore; };`.
3. Build and run: `nix build -f <astro_nix> mypkg` / `nix shell -f <astro_nix> mypkg --command bash`.

Repo rules to follow (see AGENTS.md at the repo root):

- Always fill `meta` with `description`, `homepage`, `license`, `maintainers`.
- Set `enableParallelBuilding = true` (add a comment if memory-hungry).
- Prefer patch files over inline build/source edits; format the recipe
  (`scripts/do_format.sh`).
- Pin remote sources with an exact `rev` and `sha256`, and bump versions only via the
  `version = "..."` attribute so `fetchFromGitHub { rev = "v${version}"; }` stays in sync.
- Never rely on `builtins.currentSystem`: the root `default.nix` takes `system`
  explicitly (`import ./default.nix { inherit system; }`, as `flake.nix` does), and
  `config` overrides build settings (`--arg config '{ cudaArch = [ "sm_90" ]; }'`;
  defaults live in `config.nix`, which sets `allowUnfree = true`).

### 6.4 Python recipe composition

For pure-Python or pybind packages, prefer `python3Packages.buildPythonPackage`; the
result is directly usable in `python3.withPackages`. To wrap a plain
`stdenv.mkDerivation` that installs a Python layout, use
`python3Packages.toPythonModule` (see `xtensor-python/default.nix`). For C++
packages with optional Python bindings, the `radler` pattern is the reference: one
source, one recipe, a boolean parameter selecting the builder.

## 7. Key recipes and patterns

- **`astroPyEnv` / `ddfPyEnv` / `ddfPyEnvDev`** — ready-made Python envs (see §5).
- **Python bindings for a C++ package** — `python3Packages.radler`;
  `python3Packages.dp3`, `python-casacore`, `ddfacet`, `killms`, `lofarbeam`,
  `ddf-pipeline`, ... follow the same idea.
- **Variants** — `oskarWithGUI` (`pkgs.libsForQt5.callPackage ./oskar/default.nix { withGUI = true; ... }`),
  `openblasSingleThreaded` (`singleThreaded = true; blas64 = false`), `aleaWithCuda`
  (`cudaPackages = pkgs.cudaPackages`; host-only build passes `cudaPackages = null`;
  the CUDA tests need `sandbox = false` in nix.conf).
- **Optional features** — `wsclean` takes `ska-sdp-func = null` by default; enable it
  when wiring the recipe by passing `ska-sdp-func`.
- **Vendored submodules removed** — `wsclean`, `aoflagger`, `idg`, `everybeam` delete
  vendored submodules in `postPatch` and symlink the astro-nix packaged versions;
  keep those versions consistent when editing recipes.
- **Overriding a low-level package rebuilds everything downstream** (casacore →
  aocommon → schaapcommon/radler/idg/everybeam → wsclean/dp3/...). Prefer overriding
  at the top-level package unless you intend a full-stack rebuild. See the dependency
  graph in [references/packages.md](references/packages.md).

## 8. Troubleshooting

- **`experimental Nix feature 'nix-command'/'flakes' is disabled`** — add
  `extra-experimental-features = nix-command flakes` to `nix.conf` (see Setup), or
  pass `--extra-experimental-features 'nix-command flakes'` to the command.
- **Long compile times** — the binary cache is missing/untrusted. Add the two
  `nix.conf` lines from Setup (no clone needed; with root + clone,
  `sudo ./scripts/nix-command-edit.sh` does it). Check with
  `nix show-config | grep -i substituter`, and see what would be fetched vs built:
  `nix build -f <astro_nix> wsclean --dry-run`.
- **`nix search` is slow** — searching `".*"` evaluates the whole set. Use the
  `attrNames` one-liner in §1 or [references/packages.md](references/packages.md).
  Remember `nix search <astro_nix>` covers only astro-nix packages; upstream is
  `nix search nixpkgs ...`.
- **Rootless / HPC** — install a static nix binary, put the store on a fast local
  filesystem (e.g. project dir on Lustre, never NFS), and use this `~/.config/nix/nix.conf`
  (full walkthrough: `doc/rootless-nix.md` inside the repo):

  ```
  store = /path/to/your/software/store
  extra-experimental-features = nix-command flakes
  ssl-cert-file = /etc/ssl/certs/ca-certificates.crt   # or /etc/pki/tls/certs/ca-bundle.crt
  extra-substituters = https://cache.astro-nix.space/
  extra-trusted-public-keys = astro-nix-secret:QASg0gb6rH/PxxthSsoGvw739dyKwEIVnhhhD7wA02A=
  ignored-acls = lustre.lov
  ```

- **Reproducibility** — pin astro-nix to a commit (`archive/<sha>.tar.gz` URL or
  `github:adevress/astro-nix/<sha>` as the `<astro_nix>` value), and in Nix
  expressions use `fetchTarball` with a `sha256`, so all machines resolve the
  identical source tree and share cache paths.

## 9. MPI (Open MPI / mpi4py)

Minimal Open MPI examples:

```bash
nix run -f <astro_nix> mpi-hello-cpp                 # C++
nix run -f <astro_nix> python3Packages.mpi-hello     # Python / mpi4py (alias: mpi-hello-python)
```

On a Slurm HPC cluster, launch directly through the site PMIx plugin (plugin name
must match the cluster PMIx version — `pmix_v5`, `pmix_v6`, ...; or set
`MpiDefault=pmix_v5` in `slurm.conf` / `export SLURM_MPI_TYPE=pmix_v5`):

```bash
srun --mpi=pmix_v5 nix run -f <astro_nix> mpi-hello-cpp
srun --mpi=pmix_v5 nix run -f <astro_nix> python3Packages.mpi-hello
```

For local testing without Slurm, use `mpiexec` from the exposed `openmpi` attribute
(the same Open MPI build mpi4py is linked against):

```bash
nix shell -f <astro_nix> mpi-hello-cpp openmpi --command bash -c 'mpiexec -n 2 mpi-hello-cpp'
nix shell -f <astro_nix> python3Packages.mpi-hello openmpi --command bash -c 'mpiexec -n 2 mpi-hello'
```

See `mpi-hello/README.md` in the repo for details.

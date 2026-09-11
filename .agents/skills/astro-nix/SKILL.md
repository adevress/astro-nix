---
name: astro-nix
description: Use Nix and the astro-nix radio-astronomy package set (wsclean, casacore, aoflagger, oskar, dysco, ds9, astroPyEnv). Use when running tools, opening shells, building Python envs, or adding/editing Nix packages in this repo.
---

# Astro-Nix

Collection of Nix recipes for astronomy & radio-astronomy. Repo root is a
Nix expression (`default.nix`, pinned `nixpkgs-25.11`), **not** a flake.
Invoke with legacy file mode: `nix <cmd> -f ./ <attr>`.

Repo root for all paths below: `/home/adrien/workspace/astro-nix`
(or `$CWD` when your session is already there — prefer relative paths).

## 1. Run a command

```bash
nix run -f ./ ds9                              # DS9 viewer
nix shell -f ./ wsclean --command wsclean -h   # one-shot in wsclean env
nix shell -f ./ casacore --command readms      # casacore tool
```

Rule: `nix run -f ./ <attr>` executes `$out/bin/<name>` (resolved via
`meta.mainProgram > pname > name`). `nix shell -f ./ <attr> --command <cmd>`
puts it on `PATH` and runs `<cmd>`. See [cheatsheet](references/nix-cheatsheet.md).

## 2. Get a shell

```bash
nix shell -f ./ casacore --command bash   # runtime shell (preferred here)
nix shell -f ./ astroPyEnv --command bash # Python env shell
nix-shell -A wsclean ./                   # classic attr access
nix develop -f ./ wsclean                 # build-env shell (phases, stdenv/setup)
```

`nix shell` = runtime `$PATH` only. `nix develop` / `nix-shell` = full
build environment (`configurePhase`, `buildPhase`, `shellHook`).

## 3. Python environment

Prebuilt env `astroPyEnv` (radler + numpy/scipy/dask/xarray/matplotlib/astropy):

```bash
nix shell -f ./ astroPyEnv --command bash
python -c "import astropy; print('Success!')"
```

Ad-hoc (upstream `python.withPackages` pattern):

```bash
nix-shell -p 'python313.withPackages (ps: with ps; [numpy astropy])'
```

Custom envs are `python.withPackages (ps: [...])` expressions — see
[python guide](references/python.md).

## 4. Edit / add a package

Each package is `<name>/default.nix` as a `stdenv.mkDerivation` /
`buildPythonPackage` function, wired in `default.nix` via `callPackage`:

```bash
ls wsclean/default.nix casacore/default.nix aoflagger/default.nix
./scripts/list-attrs.sh   # helper: list top-level attrs (see scripts/)
```

Workflow:

1. Read `references/packages.md` for the dependency graph + versioning rules.
2. Edit `<pkg>/default.nix` (`src.rev` + `sha256`, `buildInputs`, `patches/`, `cmakeFlags`).
3. Register in `default.nix`: `foo = pkgs.callPackage ./foo/default.nix { inherit aocommon casacore; };`
4. Verify: `nix build -f ./ foo --print-out-paths --print-build-logs`

Conventions: keep `fetchgit` + pinned `rev` + `sha256`, add patches as
`<pkg>/*.patch` listed in `patches`, use `pkg.override { ... }` for
variants (e.g. `openblasSingleThreaded`, `radler.override { pythonBuild = true; }`,
`oskarWithGUI`). `nix edit` does **not** work here (no `meta.position` on file attrs) — edit files directly.

## 5. Build, CI, cache

```bash
nix build -f ./ wsclean --print-out-paths --print-build-logs
nix log -f ./ wsclean
./scripts/do_format.sh  # nixpkgs-fmt check
```

CI (`.github/workflows/nix-build.yml`, `ci/astro-derivations.json`,
`ci/ci_build.sh`) builds 9 attrs on `x86_64+aarch64` and pushes to
`s3://astro-nix` → `https://cache.astro-nix.space/`. Prebuilt binaries exist
for Linux `x86_64`/`aarch64` only. Do not run `build_all_derivation` locally
unless pushing to cache.

## 6. Search packages

`nix search` works against this repo via the **flake** (`.`), not the legacy
`-f ./` file mode. It searches the entire `legacyPackages` set exposed by
`flake.nix` (the repo's astro/python packages **plus** the full pinned
upstream nixpkgs 25.11 source), on both `x86_64-linux` and `aarch64-linux`.

```bash
nix search . wsclean      # -> legacyPackages.x86_64-linux.wsclean
nix search . casacore     # -> casacore AND dysco (desc mentions Casacore)
nix search . oskar       # -> oskar AND oskarWithGUI
nix search . nonexistent  # no results, exit code 1
```

Behavior / gotchas:

- **Scope is the whole nixpkgs set**, not just the radio-astronomy packages.
  Unrelated upstream packages (`AusweisApp2`, `CuboCore`, …) are in scope,
  so expect a long evaluation walk before results print.
- **Matching is fuzzy/substring** on name + description, hence `casacore`
  also surfaces `dysco`. This is standard `nix search` behavior.
- **Falls back to `x86_64-linux`** automatically when run on that platform.
- Uses `.` (flake). The legacy `nix search -f ./ <pkg>` form does **not**
  apply here — `-f ./` exposes top-level `callPackage` attrs, not the
  `legacyPackages` set that `nix search` requires.

## References

- [nix-cheatsheet](references/nix-cheatsheet.md) — run/shell/develop/build/log/eval/search
- [packages](references/packages.md) — inventory, dependency graph, edit rules
- [python](references/python.md) — astroPyEnv, withPackages, buildPythonPackage

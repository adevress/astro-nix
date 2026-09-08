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

## 1. Setup (once per machine)

Requires Nix >= 2.34 with `nix-command` + binary cache:

```bash
nix --version  # expect 2.34.x
cat /etc/nix/nix.conf  # must contain nix-command + cache.astro-nix.space
```

- **Root install:** `sudo ./scripts/nix-command-edit.sh && sudo systemctl restart nix-daemon`
- **Rootless / HPC:** follow `doc/rootless-nix.md` (static `~/bin/nix`, custom `NIX_USER_ROOT_STORE`, `~/.config/nix/nix.conf` with `extra-substituters` + `extra-trusted-public-keys` from `config/nix-cache.source`).
- Never commit secrets (`.nix/keys/`, `.aws/credentials` are CI-only, see `ci/ci_build.sh`).

See [setup](references/setup.md).

## 2. Run a command

```bash
nix run -f ./ ds9                              # DS9 viewer
nix shell -f ./ wsclean --command wsclean -h   # one-shot in wsclean env
nix shell -f ./ casacore --command readms      # casacore tool
```

Rule: `nix run -f ./ <attr>` executes `$out/bin/<name>` (resolved via
`meta.mainProgram > pname > name`). `nix shell -f ./ <attr> --command <cmd>`
puts it on `PATH` and runs `<cmd>`. See [cheatsheet](references/nix-cheatsheet.md).

## 3. Get a shell

```bash
nix shell -f ./ casacore --command bash   # runtime shell (preferred here)
nix shell -f ./ astroPyEnv --command bash # Python env shell
nix-shell -A wsclean ./                   # classic attr access
nix develop -f ./ wsclean                 # build-env shell (phases, stdenv/setup)
```

`nix shell` = runtime `$PATH` only. `nix develop` / `nix-shell` = full
build environment (`configurePhase`, `buildPhase`, `shellHook`).

## 4. Python environment

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

## 5. Edit / add a package

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

## 6. Build, CI, cache

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

## References

- [setup](references/setup.md) — daemon/rootless install, cache keys
- [nix-cheatsheet](references/nix-cheatsheet.md) — run/shell/develop/build/log/eval
- [packages](references/packages.md) — inventory, dependency graph, edit rules
- [python](references/python.md) — astroPyEnv, withPackages, buildPythonPackage

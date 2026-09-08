# Nix cheatsheet (for this repo)

Repo is **not** a flake. Every command below runs from the repo root
(`default.nix`). Upstream docs: `nixos.org/manual/nix/stable/command-ref/new-cli/nix3-{run,env-shell,develop,build,edit}`.

## Run vs shell vs develop

| Goal | Command |
|---|---|
| Run app directly | `nix run -f ./ ds9` (+ args after `--`, e.g. `nix run -f ./ ds9 -- --help`) |
| One command in env | `nix shell -f ./ wsclean --command wsclean -h` |
| Interactive env | `nix shell -f ./ casacore --command bash` |
| Build env (phases) | `nix develop -f ./ wsclean` then `configurePhase/buildPhase/installPhase` |
| Classic shell | `nix-shell -A <attr> ./` or `nix-shell -p <pkg>` |
| Script shebang | `#!/usr/bin/env nix` + `#! nix shell <ref> --command python` |

`nix shell` = runtime `$PATH` only, drops to `$SHELL` with no `--command`.
`nix develop` / `nix-shell` source `$stdenv/setup` + `shellHook`.

## Build / inspect / debug

```bash
nix build -f ./ wsclean --print-out-paths --print-build-logs  # -> ./result symlink
nix build -f ./ wsclean --no-link --print-out-paths           # CI style, no symlink
nix log -f ./ wsclean              # cached build log
nix eval -f ./ wsclean --apply 'p: p.version'
nix path-info -f ./ wsclean
nix why-depends -f ./ wsclean casacore
nix copy -f ./ --to 's3://...' wsclean   # cache push (CI only)
```

CI builds in order (`ci/astro-derivations.json`): `openblasSingleThreaded.all`,
`wsclean`, `aoflagger`, `python3Packages.radler`, `casacore`, `dysco`,
`oskar`, `ds9`, `astroPyEnv`.

## Eval gotchas

- `default.nix` returns `pkgs // astro_pkgs // py_astro_pkgs`, so **any**
  nixpkgs attr also resolves (`nix build -f ./ hello`).
- `-f ./ <attr>` selects the attr; `-A <attr>` is the `nix-shell`/`nix-build` spelling.
- `result` / `result-dev` symlinks at repo root are build leftovers — ignore, don't commit.
- `nix edit -f ./ wsclean` does not resolve (no flake/`meta.position` wiring); edit `<pkg>/default.nix` directly.

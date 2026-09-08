# Packages: inventory, graph, edit rules

## Inventory (`<pkg>/default.nix`)

| Attr | Version / src | Notes |
|---|---|---|
| `openblasSingleThreaded` | `pkgs.openblas.override { singleThreaded = true; }` | avoids casacore/aocommon threading bugs; see `Makefile`, `test_openblas.c` |
| `wcstools`, `wcslib` | upstream WCS | leaf deps |
| `casacore` | `3.8.0` (github `casacore/casacore@v3.8.0`) | `openblasSingleThreaded` + `wcslib` |
| `aocommon` | ASTRON git | `blas-check.patch`, `xtensor-path{,2}.patch` |
| `schaapcommon` | ASTRON git | `schapcommon-{dep-reso,xtensor-path}.patch` |
| `radler` | `1.0.0` (`git.astron.nl/RD/radler`) | `001-pybind-version-fix.patch`, `radler-set-cpu-flag.patch`; `pythonBuild` flag switches `mkDerivation` → `buildPythonPackage` |
| `wsclean` | `3.7-dev` (`gitlab.com/aroffringa/wsclean@2b1a430`) | symlinks `external/{aocommon,radler,schaapcommon}` to Nix outputs in `postPatch`; `idg`/`ska-sdp-func` nullable (`? null`) |
| `everybeam` | `0.8.2` | needs `aocommon schaapcommon ska-sdp-func` |
| `idg` | `1.2.0` | `001-xtensor-path-update.patch` |
| `dysco` | `2024-03-29` | `casacore` storage manager |
| `aoflagger` | `dev` (`@c868186`) | newest addition |
| `ska-sdp-func` | `1.2.2` | SKA SDP func lib |
| `oskar` / `oskarWithGUI` | `2.12.2` | GUI via `libsForQt5.callPackage ... { withGUI = true; }` |
| `ds9` | `8.7` (`ds9.si.edu` tarball) | tcl/tk viewer |
| `xtensor-fftw`, `xtensor-python` | backports | see recent `xtensor-python` commits |
| `hello` | local `hello.c` | example only |

Python overlay: `python3Packages.radler = astro_pkgs.radler.override { pythonBuild = true; }`, plus `xtensor-python`.

## Dependency graph

```
wcslib ─┐
        ├─ casacore ─┬─ aocommon ─┬─ schaapcommon ─┬─ radler ─┐
openblas(S) ─────────┘            │                │          ├─ wsclean
                                  │                ├─ idg ────┘
                                  │                ├─ everybeam (+ska-sdp-func)
                                  │                └─ aoflagger (aocommon only)
                                  └─ dysco (casacore only)
ska-sdp-func ─┬─ oskar(/WithGUI) (+casacore)
              └─ everybeam
```

## Edit rules

1. **Pin everything:** `fetchgit { url, rev, sha256 }` or `fetchFromGitHub { owner, repo, rev, sha256 }`. Bump `version` + `rev` together; get new hash via `nix build` fake-hash error or `nix hash`.
2. **Patches live next to the derivation:** `<pkg>/*.patch`, listed in `patches = [...]`. Keep them minimal and named (`001-*.patch`).
3. **Inputs:** declare in function args (`{ stdenv, cmake, aocommon, ..., lib }:`), split `nativeBuildInputs` (cmake/ninja/pkg-config/git) vs `buildInputs` (boost/fftw/cfitsio/hdf5/gsl/...). Nullable external deps as `idg ? null`.
4. **Wire-up:** add `name = pkgs.callPackage ./name/default.nix { inherit dep1 dep2; };` in `default.nix:astro_pkgs`. Use `.override` for variants, never fork the file.
5. **CI list:** add user-facing attrs to `ci/astro-derivations.json:.default[]` only if a binary should be prebuilt.
6. **Format:** run `./scripts/do_format.sh` (nixpkgs-fmt).
7. Verify with `nix build -f ./ <attr> --print-build-logs`; inspect failures with `nix log -f ./ <attr>`.

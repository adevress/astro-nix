# astro-nix package reference

All packages below are attributes of the merged set returned by the repo root `default.nix`, i.e. usable as `nix <cmd> -f ./ <name>` from the repo root. All of nixpkgs (pinned release 25.11) is also available through the same set.

## Custom astro packages

| Attribute | Description | Notes |
|---|---|---|
| `casacore` | Core radio-astronomy data/libs (MeasurementSet, `readms`, ...) | v3.8.0; built against `wcslib` + single-threaded OpenBLAS |
| `aocommon` | ASTRON common C++ utilities | depends on casacore |
| `schaapcommon` | SKA/LOFAR common C++ utilities | depends on aocommon |
| `radler` | Radio deconvolution library (C++ + optional python) | `override { pythonBuild = true; }` for bindings |
| `wsclean` | Wide-field interferometric imager | v3.7-dev; external aocommon/radler/schaapcommon; idg enabled, `ska-sdp-func = null` by default |
| `idg` | Image Domain Gridding (CPU/GPU) | used by wsclean |
| `everybeam` | Beam response models (LOFAR, SKA, ...) | |
| `ska-sdp-func` | SDP processing function library | optional input to wsclean/everybeam/oskar |
| `dysco` | MeasurementSet compression | casacore table data manager |
| `aoflagger` | RFI flagger | |
| `oskar` | SKA simulator | CLI build |
| `oskarWithGUI` | OSKAR with Qt5 GUI | |
| `wcslib` / `wcstools` | WCS library / WCS CLI tools | wcslib feeds casacore |
| `ds9` | SAOImage DS9 FITS viewer | `nix run -f ./ ds9` |
| `xtensor-fftw` | FFTW bindings for xtensor | top-level C++ package |
| `openblasSingleThreaded` | openblas with `singleThreaded = true` | used by casacore/aocommon |
| `hello` | trivial test package | smoke-test the setup |

## Python environment

| Attribute | Contents |
|---|---|
| `astroPyEnv` | python3 with radler (python bindings), scipy, numpy, dask, xarray, matplotlib, astropy |
| `python3Packages.radler` | radler built with `pythonBuild = true` |
| `python3Packages.xtensor-python` | xtensor python bindings |

To build a custom Python env, mirror `astroPyEnv` in root `default.nix`:

```nix
astro.python3Packages.python.withPackages (ps: [
  astro.python3Packages.radler
  ps.astropy ps.numpy ps.scipy ps.matplotlib
])
```

## Dependency graph

```
wcslib ──> casacore ──┬──> aocommon ──┬──> schaapcommon ──┬──> radler ──> wsclean
                      │               │                   ├──> idg ──────────┘
                      │               │                   └──> everybeam
                      │               └──> aoflagger
                      ├──> dysco
                      └──> oskar / oskarWithGUI
ska-sdp-func ─────────┴──> everybeam, oskar, (optionally wsclean)
```

Implication: overriding a low-level package (e.g. `casacore` or `openblas`) propagates to everything downstream — prefer overriding at the top-level package unless you intend a full-stack rebuild.

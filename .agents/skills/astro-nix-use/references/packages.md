# astro-nix package reference

All attributes below belong to the package set returned by the repo's `default.nix`.
Reach them with `nix <cmd> -f <astro_nix> <name>`, where `<astro_nix>` is the GitHub
tarball URL (default) or a local clone path — see SKILL.md §0 — or, via the flake, as
`legacyPackages.<system>.<name>` / `nix search <astro_nix> <name>`.

**Important:** this set contains astro-nix's own packages only. Upstream nixpkgs
packages (`python3`, `cmake`, ...) are *not* in it — use `nixpkgs#...` /
`nix search nixpkgs ...` for those. astro-nix itself pins nixpkgs **release 25.11**.

Source of truth for the wiring: `all_packages.nix` at the repo root.

## Core radio-astronomy packages

| Attribute | Description | Notes |
|---|---|---|
| `casacore` | Core radio-astronomy data/libs (MeasurementSet, `readms`, `taql`, ...) | built against `wcslib` + single-threaded LP64 OpenBLAS |
| `aocommon` | ASTRON common C++ utilities | depends on casacore |
| `schaapcommon` | SKA/LOFAR common C++ utilities | depends on aocommon |
| `radler` | Radio deconvolution library (C++ + optional Python) | `override { pythonBuild = true; }` for the bindings |
| `wsclean` | Wide-field interferometric imager | external aocommon/radler/schaapcommon/idg; `ska-sdp-func = null` by default |
| `idg` | Image Domain Gridding (CPU/GPU) | used by wsclean, dp3 |
| `everybeam` | Beam response models (LOFAR, SKA, ...) | also takes `ska-sdp-func`, `xtensor-fftw` |
| `ska-sdp-func` | SDP processing function library | optional input to wsclean; required by everybeam/oskar |
| `dysco` | MeasurementSet compression | casacore table data manager |
| `aoflagger` | RFI flagger | depends on aocommon |
| `oskar` | SKA simulator (CLI) | |
| `oskarWithGUI` | OSKAR with Qt5 GUI | `libsForQt5.callPackage ... { withGUI = true; }` |
| `cotter` | LOFAR cotter | casacore + aoflagger + pal |
| `wcslib` / `wcstools` | WCS library / WCS CLI tools | wcslib feeds casacore |
| `xtensor-fftw` | FFTW bindings for xtensor | feeds everybeam |
| `ds9` | SAOImage DS9 FITS viewer | `nix run -f <astro_nix> ds9` |
| `hello` | trivial test package | smoke-test the setup |

## Python environments and packages

| Attribute | Contents |
|---|---|
| `astroPyEnv` | python3 + radler bindings, astropy, numpy, scipy, dask, xarray, matplotlib, mapbox-earcut |
| `ddfPyEnv` / `ddfPyEnvDev` | full DDF pipeline stack (ddf-pipeline, ddfacet, killms + astropy/scipy/numpy/matplotlib/pandas/dask); `Dev` = git snapshots |

`python3Packages` is `pkgs.python3Packages.overrideScope ...` extended with astro
bindings: `radler` (pythonBuild), `xtensor-python`, `mapbox-earcut`, `dp3`,
`ddfacet` (+`ddfacet_dev`), `killms` (+`killms_dev`), `ddf-pipeline` (+`_dev`),
`python-casacore`, `lofarbeam`, `meqtrees-cattery`, `codex-africanus`, `bdsf`,
`regions`, `pyfftw`, `pyephem`, `sharedarray`, `purr`, `pdu`, `treepick`, `yorn`,
`torch-cuda`, and `mpi4py` rebuilt against the astro `openmpi`.

Build a custom env with:

```nix
astro.python3Packages.python.withPackages (ps: [
  ps.radler ps.astropy ps.numpy ps.scipy ps.matplotlib
])
```

## MPI, GPU, SDR, and utility packages

| Attribute | Description | Notes |
|---|---|---|
| `mpi-hello-cpp` | minimal Open MPI hello world (C++) | `srun --mpi=pmix_v5 nix run -f <astro_nix> mpi-hello-cpp` on Slurm |
| `python3Packages.mpi-hello` | Python/mpi4py hello world | alias: `mpi-hello-python` |
| `openmpi` | the Open MPI build used above (PMIx-enabled) | for `mpiexec` in local tests |
| `alea` | counter-based RNGs (threefry, philox, ars), C++20 header-only | `callPackage { validation = true; }` also runs the random123 comparison tests |
| `aleaWithCuda` | `alea` + GPU tests | `cudaPackages = null` gives the host-only cacheable build; CUDA tests need `sandbox = false` |
| `cuda-hello` | minimal CUDA test program | `nix build -f <astro_nix> cuda-hello --arg config '{ cudaArch = [ "sm_90" ]; }'` |
| `nixgpu` | host GPU driver wrapper | `nix run -f <astro_nix> nixgpu -- <program>` |
| `cyberether` / `blade` | CyberEther SDR visualizer / BLADE library | CyberEther needs the bundled `meson`, `glfw`, `glm`, `rapidyaml`, `cpp-httplib`, `nlohmann_json`, `nanobench`, `nanobind`, `robin-map`, `libmodes`, `stb` |
| `soapysdrWithPlugins` | SoapySDR + SDR driver plugins | discovered at runtime |
| `openblasSingleThreaded` | openblas `singleThreaded = true; blas64 = false` | LP64, used by casacore/aocommon/python-casacore/dp3/lofarbeam |
| `dp3TestData` | test data for the DP3 test suite | |

## Dependency graph

```
wcslib ──> casacore ──┬──> aocommon ──┬──> schaapcommon ──┬──> radler ──┬──> wsclean
                      │  (LP64 single- │               │               │       ├──> dp3 (python)
                      │  threaded      ├──> aoflagger  ├─> idg ────────┤       └──> ...
                      │  openblas)     │               └─> everybeam <-┴── xtensor-fftw
                      │                └──> cotter (pal)      ^               ska-sdp-func
                      ├──> dysco                               └──────────────────────┘
                      ├──> python-casacore, lofarbeam           ska-sdp-func ──> oskar / oskarWithGUI
                      └──> oskar / oskarWithGUI (ska-sdp-func)
```

Implication: overriding a low-level package (e.g. `casacore` or `openblas`) propagates
to everything downstream — prefer overriding at the top-level package unless you intend
a full-stack rebuild.

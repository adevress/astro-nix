{ lib, pkgs }:
lib.makeScope pkgs.newScope (
  self: with self; {
    # astro_pkgs
    hello = callPackage ./hello/default.nix { };

    # MPI hello worlds.  Open MPI is nixpkgs' PMIx-enabled build (it is
    # configured with `--with-pmix`), so programs linked against it can be
    # started directly by Slurm's `srun` PMIx plugin.  Exposing the same
    # Open MPI here also lets the Python package set build mpi4py against it.
    openmpi = pkgs.openmpi;
    mpi-hello-cpp = callPackage ./mpi-hello/default.nix { inherit openmpi; };

    # Meson >= 1.11 override (upstream nixpkgs recipe, version bumped; CyberEther needs it)
    meson = callPackage ./meson/default.nix { };

    # Legacy CyberEther 1.x meson subproject bundles (flat namespace; sources
    # pinned to the exact revisions the 1.x .wrap files commit). CyberEther 2.0
    # uses its own pinned MESON_PACKAGE_CACHE_DIR in cyberether/default.nix and
    # takes fmt/glfw/glm/rapidyaml/nlohmann_json/libzmq/httplib/nanobench/
    # robin-map/stb/miniz/miniaudio/tree-sitter/Catch2 and most SDR vendors from
    # Nixpkgs, and pocketfft/LimeSuiteNG from this repo, so these attrs are no
    # longer referenced by the cyberether recipe.
    glfw = callPackage ./glfw/default.nix { };
    glm = callPackage ./glm/default.nix { };
    # Nixpkgs 25.11 ships rapidyaml 0.10.0, whose error-callback API predates
    # the 0.11 API used by CyberEther 2.0. Keep the Nixpkgs recipe and bump
    # only the source. PIC is required because CyberEther links the static
    # rapidyaml/c4core archives into libjetstream.so.
    rapidyaml = pkgs.rapidyaml.overrideAttrs (
      finalAttrs: prev: {
        version = "0.11.1";
        src = pkgs.fetchFromGitHub {
          owner = "biojppm";
          repo = "rapidyaml";
          fetchSubmodules = true;
          tag = "v${finalAttrs.version}";
          hash = "sha256-NjpEpjBFB2Ydfo81VzOYoMPqMdJbIYcQWBRcxCbJlY4=";
        };
        cmakeFlags = (prev.cmakeFlags or [ ]) ++ [ "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" ];
      }
    );
    # Nixpkgs 25.11 ships httplib 0.19.0, which predates the `httplib::ws`
    # WebSocket API used by CyberEther 2.0. Keep the Nixpkgs recipe and bump
    # only the source version.
    httplibSystem = pkgs.httplib.overrideAttrs (
      finalAttrs: prev: {
        version = "0.63.0";
        src = pkgs.fetchFromGitHub {
          owner = "yhirose";
          repo = "cpp-httplib";
          rev = "v${finalAttrs.version}";
          hash = "sha256-w+KNRi+m4Bktq7xFYob/kb0AS84xiGl32cGspYwNkx8=";
        };
      }
    );
    # Nixpkgs 25.11 ships hackrf 2024.02.1, which predates the BOARD_ID_PRALINE
    # definition used by CyberEther 2.0. Keep the Nixpkgs recipe and bump only
    # the source version (the old CMake <3.5 compatibility patch is obsolete).
    hackrfSystem = pkgs.hackrf.overrideAttrs (
      finalAttrs: prev: {
        version = "2026.01.3";
        src = pkgs.fetchFromGitHub {
          owner = "greatscottgadgets";
          repo = "hackrf";
          rev = "v${finalAttrs.version}";
          hash = "sha256-/RSZ+jkh4wmb0n8Kiee9Nr5D6LPYdmZVigpsBagAaLg=";
        };
        patches = [ ];
        postPatch = "";
      }
    );
    cpp-httplib = callPackage ./cpp-httplib/default.nix { };
    nlohmann_json = callPackage ./nlohmann_json/default.nix { };
    nanobench = callPackage ./nanobench/default.nix { };
    nanobind = callPackage ./nanobind/default.nix { };
    robin-map = callPackage ./robin-map/default.nix { };
    libmodes = callPackage ./libmodes/default.nix { };
    stb = callPackage ./stb/default.nix { };

    # Header-only FFT used by CyberEther's CPU FFT blocks.
    pocketfft = callPackage ./pocketfft/default.nix { };

    # LimeSuiteNG 25.1.0: the `limesuiteng` API required by CyberEther 2.x
    # (Nixpkgs only has the legacy `limesuite` release).
    limesuiteng = callPackage ./limesuiteng/default.nix { };

    # Generic C++ libraries (header only, no astronomy dependency)
    alea = callPackage ./alea/default.nix {
      cudaPackages = null; # host only build, free software, cacheable
    };

    aleaWithCuda = callPackage ./alea/default.nix {
      cudaPackages = pkgs.cudaPackages;
    };

    # specialization of packaged
    #
    # nixpkgs >= 25.11 defaults OpenBLAS to ILP64 (64-bit integers) on
    # x86_64, while the reference BLAS/LAPACK API used by casacore,
    # aocommon and DP3 passes 32-bit ``int`` arguments.  Forcing LP64 keeps
    # the BLAS integer width consistent on every platform; on aarch64 the
    # default already is LP64, so this is a no-op there.
    openblasSingleThreaded = pkgs.openblas.override {
      singleThreaded = true;
      blas64 = false;
    };

    # Astronomy packages
    wcstools = callPackage ./wcstools/default.nix { };
    wcslib = callPackage ./wcslib/default.nix { };
    casacore = callPackage ./casacore/default.nix {
      openblas = openblasSingleThreaded;
      inherit wcslib;
    };
    aocommon = callPackage ./aocommon/default.nix {
      openblas = openblasSingleThreaded;
      inherit casacore;
    };
    schaapcommon = callPackage ./schaapcommon/default.nix { inherit aocommon; };
    radler = callPackage ./radler/default.nix { inherit aocommon schaapcommon casacore; };
    wsclean = callPackage ./wsclean/default.nix {
      inherit
        aocommon
        radler
        schaapcommon
        idg
        ;
      ska-sdp-func = null;
    };
    ska-sdp-func = callPackage ./ska-sdp-func/default.nix { };
    xtensor-fftw = callPackage ./xtensor-fftw/default.nix { };
    everybeam = callPackage ./everybeam/default.nix {
      inherit
        aocommon
        schaapcommon
        ska-sdp-func
        xtensor-fftw
        ;
    };
    idg = callPackage ./idg/default.nix { inherit aocommon schaapcommon; };
    dysco = callPackage ./dysco/default.nix { inherit casacore; };

    # Test data shared by the DP3 test suite: the MWA MeasurementSet and a
    # pinned casacore measures snapshot (see test_data/default.nix).
    dp3TestData = callPackage ./test_data/default.nix { };
    oskar = callPackage ./oskar/default.nix { inherit ska-sdp-func casacore; };
    oskarWithGUI = pkgs.libsForQt5.callPackage ./oskar/default.nix {
      withGUI = true;
      inherit casacore ska-sdp-func;
    };
    aoflagger = callPackage ./aoflagger/default.nix { inherit aocommon; };
    pal = callPackage ./pal/default.nix { };
    cotter = callPackage ./cotter/default.nix {
      inherit
        casacore
        aoflagger
        pal
        ;
    };
    ds9 = callPackage ./ds9/default.nix { };

    # Host GPU driver wrapper (nixGL-like) with CUDA support.
    # `nix run -f ./ nixgpu -- <program>` runs <program> with the host drivers.
    nixgpu = callPackage ./nixgpu/default.nix {
      # intel-media-driver only exists on x86; it is simply omitted elsewhere.
      intel-media-driver = if pkgs.stdenv.hostPlatform.isx86 then pkgs.intel-media-driver else null;
    };

    # Small CUDA test program, built hermetically with the Nix CUDA toolkit.
    cuda-hello = callPackage ./cuda-hello/default.nix {
      cudaPackages = pkgs.cudaPackages_13_0;
      inherit (astroConfig) cudaArch;
    };

    # CyberEther's build-time Python (geodata, shader/docs parsers and the
    # nanobind bindings) only needs the standard library; numpy is kept for the
    # Superluminal runtime API.
    cyberetherPython = python3Packages.python.withPackages (ps: [
      python3Packages.numpy
    ]);

    cyberether = callPackage ./cyberether/default.nix {
      inherit
        meson
        rapidyaml
        pocketfft
        limesuiteng
        ;
      qrencode = pkgs.qrencode;
      tomlplusplus = pkgs.tomlplusplus;
      # The local glfw/glm/nlohmann_json attrs are meson wrap bundles for the
      # 1.x recipe; force the real Nixpkgs libraries for CyberEther 2.0.
      glfw = pkgs.glfw;
      glm = pkgs.glm;
      fmt = pkgs.fmt;
      nlohmann_json = pkgs.nlohmann_json;
      zeromq = pkgs.zeromq;
      httplib = httplibSystem;
      nanobench = pkgs.nanobench;
      robin-map = pkgs.robin-map;
      stb = pkgs.stb;
      miniz = pkgs.miniz;
      miniaudio = pkgs.miniaudio;
      tree-sitter = pkgs.tree-sitter;
      tree-sitter-grammars = pkgs.tree-sitter.withPlugins (p: [
        p.tree-sitter-python
        p.tree-sitter-markdown
        p.tree-sitter-yaml
        p.tree-sitter-bash
        p.tree-sitter-cpp
        p.tree-sitter-json
      ]);
      catch2_3 = pkgs.catch2_3;
      rtlsdr = pkgs.rtl-sdr;
      airspy = pkgs.airspy;
      airspyhf = pkgs.airspyhf;
      hackrf = hackrfSystem;
      libbladeRF = pkgs.libbladeRF;
      libad9361 = pkgs.libad9361;
      libiio = pkgs.libiio;
      libusb1 = pkgs.libusb1;
      geodata = callPackage ./cyberether/geodata/default.nix { };
      python3 = cyberetherPython;
    };

    # py_astro_pkgs
    python3Packages = pkgs.python3Packages.overrideScope (
      final: prev: {
        # Keep mpi4py on the same Open MPI build as mpi-hello-cpp.  Open MPI's
        # external PMIx support is what makes direct `srun` launch work.
        mpi4py = prev.mpi4py.override { mpi = openmpi; };
        mpi-hello = final.callPackage ./mpi-hello/python.nix { };
        #pythonPackagesExtensions = pkgs.pythonPackagesExtensions ++ [
        #  (python-final: python-prev: {
        radler = radler.override { pythonBuild = true; };
        xtensor-python = callPackage ./xtensor-python/default.nix { };
        mapbox-earcut = callPackage ./mapbox-earcut/default.nix {
          inherit (pkgs.python3Packages)
            buildPythonPackage
            scikit-build-core
            nanobind
            numpy
            pathspec
            ;
          cmake = pkgs.cmake;
          ninja = pkgs.ninja;
        };

        # DDF pipeline Python packages (dependency order matters)
        sharedarray = final.callPackage ./sharedarray/default.nix { };
        pyephem = final.callPackage ./pyephem/default.nix { };
        pyfftw = final.callPackage ./pyfftw/default.nix {
          fftw = pkgs.fftw;
          fftwFloat = pkgs.fftwFloat;
        };
        regions = final.callPackage ./regions/default.nix { };
        codex-africanus = final.callPackage ./codex-africanus/default.nix { };
        bdsf = final.callPackage ./bdsf/default.nix {
          boost = pkgs.boost.override {
            enablePython = true;
            enableNumpy = true;
            python = pkgs.python3;
          };
        };
        purr = final.callPackage ./purr/default.nix { };
        pdu = final.callPackage ./pdu/default.nix { };
        treepick = final.callPackage ./treepick/default.nix { };
        yorn = final.callPackage ./yorn/default.nix { };

        python-casacore = final.callPackage ./python-casacore/default.nix {
          casacore = casacore;
          boost = pkgs.boost.override {
            enablePython = true;
            python = pkgs.python3;
          };
          wcslib = wcslib;
          cfitsio = pkgs.cfitsio;
          readline = pkgs.readline;
          # Must match the OpenBLAS linked into casacore (see
          # openblasSingleThreaded above); loading two OpenBLAS variants with
          # the same SONAME but different integer widths would be undefined.
          openblas = openblasSingleThreaded;
        };

        meqtrees-cattery = final.callPackage ./meqtrees-cattery/default.nix { };

        # DP3 Python package (pybind11 bindings + DP3.py CLI).  Built through
        # CMake, using the astro-nix casacore/aoflagger/everybeam/idg.
        dp3 = final.callPackage ./dp3/default.nix {
          inherit
            casacore
            aoflagger
            everybeam
            idg
            dysco
            ;
          inherit (dp3TestData) mwaTestMs casarc;
          openblas = openblasSingleThreaded;
        };

        ddfacet = final.callPackage ./ddfacet/default.nix { };

        lofarbeam = final.callPackage ./lofarbeam/default.nix {
          casacore = casacore;
          openblas = openblasSingleThreaded;
        };

        killms = final.callPackage ./killms/default.nix { };

        # Git-tracked development snapshots (see instructions/ddf_dev.md).
        ddfacet_dev = final.callPackage ./ddfacet/dev.nix { };

        killms_dev = final.callPackage ./killms/dev.nix {
          ddfacet = final.ddfacet_dev;
        };

        ddf-pipeline = final.callPackage ./ddf-pipeline/default.nix { };

        # CUDA-enabled PyTorch binary wheel (aarch64/GB10 + x86_64).  Kept
        # separate from the nixpkgs `torch-bin` default wheel and the
        # `torchWithCuda` source build.
        torch-cuda = final.callPackage ./torch-cuda {
          cudaPackages = pkgs.cudaPackages_13_0;
        };

        ddf-pipeline_dev =
          (final.callPackage ./ddf-pipeline/default.nix {
            ddfacet = final.ddfacet_dev;
            killms = final.killms_dev;
          }).overrideAttrs
            (old: {
              version = "0.1.0";
              src = builtins.fetchGit {
                url = "https://github.com/mhardcastle/ddf-pipeline";
                ref = "refs/heads/HackathonRennes_June26";
                rev = "2a7648d2ac866f69f9a25eed1d64b73bc2b25589";
              };
            });
      }
    );

    # Convenience alias so the Python hello world can also be selected without
    # spelling out the Python package set.
    mpi-hello-python = python3Packages.mpi-hello;

    astroPyEnv = pkgs.python3Packages.python.withPackages (ps: [
      python3Packages.radler
      python3Packages.mapbox-earcut
      ps.scipy
      ps.numpy
      ps.dask
      ps.xarray
      ps.matplotlib
      ps.astropy
    ]);

    # Full DDF pipeline Python environment
    ddfPyEnv = pkgs.python3Packages.python.withPackages (ps: [
      python3Packages.ddf-pipeline
      python3Packages.ddfacet
      python3Packages.killms
      ps.astropy
      ps.scipy
      ps.numpy
      ps.matplotlib
      ps.pandas
      ps.dask
    ]);

    # Development (Git) variant of the DDF environment.
    ddfPyEnvDev = pkgs.python3Packages.python.withPackages (ps: [
      python3Packages.ddf-pipeline_dev
      python3Packages.ddfacet_dev
      python3Packages.killms_dev
      ps.astropy
      ps.scipy
      ps.numpy
      ps.matplotlib
      ps.pandas
      ps.dask
    ]);
  }
)

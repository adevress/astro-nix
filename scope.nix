{ lib, pkgs }:
lib.makeScope pkgs.newScope (self: with self; {
  # astro_pkgs
  hello = callPackage ./hello/default.nix { };
  
  # Meson >= 1.11 override (upstream nixpkgs recipe, version bumped; CyberEther needs it)
  meson = callPackage ./meson/default.nix { };
  
  # CyberEther meson subproject bundles (flat namespace; sources pinned to
  # the exact revisions CyberEther's .wrap files commit). fmt is not bundled
  # here: CyberEther's fmt loader is patched to use the system libfmt via
  # pkg-config (see cyberether/patches/006-use-system-fmt.patch).
  glfw = callPackage ./glfw/default.nix { };
  glm = callPackage ./glm/default.nix { };
  rapidyaml = callPackage ./rapidyaml/default.nix { };
  cpp-httplib = callPackage ./cpp-httplib/default.nix { };
  nlohmann_json = callPackage ./nlohmann_json/default.nix { };
  nanobench = callPackage ./nanobench/default.nix { };
  nanobind = callPackage ./nanobind/default.nix { };
  robin-map = callPackage ./robin-map/default.nix { };
  libmodes = callPackage ./libmodes/default.nix { };
  stb = callPackage ./stb/default.nix { };
  
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
    inherit aocommon schaapcommon ska-sdp-func xtensor-fftw;
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
  
  # SoapySDR with the SDR driver plugins CyberEther supports, joined into the
  # SoapySDR output with Nixpkgs' own `extraPackages` mechanism so that
  # SoapySDR discovers them at runtime (`SoapySDR::listModules()`).
  soapysdrWithPlugins = pkgs.soapysdr.override {
    extraPackages = [
      pkgs.soapyairspy
      pkgs.soapybladerf
      pkgs.soapyhackrf
      pkgs.soapyrtlsdr
      pkgs.limesuite
    ];
  };
  
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
  
  # CyberEther's geodata step (resources/geodata) requires a python with
  # numpy + mapbox_earcut; give the build the full interpreted env.
  cyberetherPython = python3Packages.python.withPackages (ps: [
    python3Packages.numpy
    python3Packages.mapbox-earcut
  ]);

  cyberether = callPackage ./cyberether/default.nix {
    inherit
      meson
      glfw
      glm
      rapidyaml
      cpp-httplib
      nlohmann_json
      nanobench
      nanobind
      robin-map
      libmodes
      stb
    ;
    qrencode = pkgs.qrencode;
    fmt = pkgs.fmt;
    tomlplusplus = pkgs.tomlplusplus;
    soapysdr = soapysdrWithPlugins;
    # Nixpkgs renamed librtlsdr to rtl-sdr; the recipe uses `rtlsdr` as a
    # valid Nix identifier.
    rtlsdr = pkgs.rtl-sdr;
    geodata = callPackage ./cyberether/geodata/default.nix { };
    # Fixed CyberEther (see below); BLADE links against its jetstream library.
    python3 = cyberetherPython;
  };
  blade = callPackage ./blade/default.nix { };
                             
  # py_astro_pkgs
  python3Packages = pkgs.python3Packages.overrideScope (final: prev: {
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
        boost = pkgs.boost.override { enablePython = true; enableNumpy = true; python = pkgs.python3; };
      };
      purr = final.callPackage ./purr/default.nix { };
      pdu = final.callPackage ./pdu/default.nix { };
      treepick = final.callPackage ./treepick/default.nix { };
      yorn = final.callPackage ./yorn/default.nix { };
      
      python-casacore = final.callPackage ./python-casacore/default.nix {
        casacore = casacore;
        boost = pkgs.boost.override { enablePython = true; python = pkgs.python3; };
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
        inherit casacore aoflagger everybeam idg dysco;
        inherit (dp3TestData) mwaTestMs casarc;
        openblas = openblasSingleThreaded;
      };

      ddfacet = final.callPackage ./ddfacet/default.nix { };
      
      killms = final.callPackage ./killms/default.nix { };
      
      # Git-tracked development snapshots (see instructions/ddf_dev.md).
      ddfacet_dev = (final.callPackage ./ddfacet/dev.nix { }).overrideAttrs (old: {
        ## Error: Private fetchFromGitHub requires the nix building process (nix-daemon in multi user mode) to have the NIX_GITHUB_PRIVATE_USERNAME and NIX_GITHUB_PRIVATE_PASSWORD env vars set.
        #src = pkgs.fetchFromGitHub {
        #  owner = "cyriltasse";
        #  repo = "DDFacet";
        #  rev = "refs/heads/HackathonRennes_June26_Adastra";
        #  hash = prev.lib.fakeHash;
        #  private = true;
        #};
        version = "0.9.1.0";
        src = builtins.fetchGit {
          url = "ssh://git@github.com/cyriltasse/DDFacet";
          ref="refs/heads/HackathonRennes_June26_Adastra";
          rev = "e8dce1e0c68e05c49cea3bfe874375680a703036";
        };
      });
      
      killms_dev = (final.callPackage ./killms/dev.nix {
        ddfacet = final.ddfacet_dev;
      }).overrideAttrs (old: {
        src = builtins.fetchGit {
          url = "ssh://git@github.com/cyriltasse/killMS";
          ref="refs/heads/HackathonRennes_June26_Adastra";
          rev = "5784d5aef6c3a2c137b5783c12216b9b661fca09";
        };
      });
      
      ddf-pipeline = final.callPackage ./ddf-pipeline/default.nix {};

      ddf-pipeline_dev = (final.callPackage ./ddf-pipeline/default.nix {
        ddfacet = final.ddfacet_dev;
        killms = final.killms_dev;
      }).overrideAttrs (old: {
        src = builtins.fetchGit {
          url = "https://github.com/mhardcastle/ddf-pipeline";
          ref="refs/heads/HackathonRennes_June26";
          rev = "2a7648d2ac866f69f9a25eed1d64b73bc2b25589";
          # TODO requires simms
          #ref="refs/heads/HackathonRennes_June26_Adastra";
          #rev = "0b6b52258414fe35c58e3229c274bdc13e530b6a";
        };
      });
    });
                               
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
    python3Packages.ddfacet_dev
    python3Packages.killms_dev
    ps.astropy
    ps.scipy
    ps.numpy
    ps.matplotlib
    ps.pandas
    ps.dask
  ]);
})

{
  system ? builtins.currentSystem,
  upstream_pkgs ? null,
  # Astro-nix build configuration.  Defaults to ./config.nix; pass a partial
  # attrset to override individual settings, e.g.
  #   nix build -f . cuda-hello --arg config '{ cudaArch = [ "sm_121" ]; }'
  config ? { },
}:
let
  astroConfig = (import ./config.nix) // config;

  # CUDA redistributables (cudaPackages) are unfree; NixGpu and cuda-hello
  # need them.  Nothing here builds an unfree package unless asked to.
  # `cudaArch` is an astro-nix setting, not a nixpkgs one, so it is not
  # forwarded to the nixpkgs import.
  pkgs =
    import
      (fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/25.11.tar.gz";
        sha256 = "1zn1lsafn62sz6azx6j735fh4vwwghj8cc9x91g5sx2nrg23ap9k";
      })
      {
        inherit system;
        config = builtins.removeAttrs astroConfig [ "cudaArch" ];
      };

  astro_pkgs = rec {

    hello = pkgs.callPackage ./hello/default.nix { };

    # Meson >= 1.11 override (upstream nixpkgs recipe, version bumped; CyberEther needs it)
    meson = pkgs.callPackage ./meson/default.nix { };

    # CyberEther meson subproject bundles (flat namespace; sources pinned to
    # the exact revisions CyberEther's .wrap files commit). fmt is not bundled
    # here: CyberEther's fmt loader is patched to use the system libfmt via
    # pkg-config (see cyberether/patches/006-use-system-fmt.patch).
    glfw = pkgs.callPackage ./glfw/default.nix { };
    glm = pkgs.callPackage ./glm/default.nix { };
    rapidyaml = pkgs.callPackage ./rapidyaml/default.nix { };
    cpp-httplib = pkgs.callPackage ./cpp-httplib/default.nix { };
    nlohmann_json = pkgs.callPackage ./nlohmann_json/default.nix { };
    nanobench = pkgs.callPackage ./nanobench/default.nix { };
    nanobind = pkgs.callPackage ./nanobind/default.nix { };
    robin-map = pkgs.callPackage ./robin-map/default.nix { };
    libmodes = pkgs.callPackage ./libmodes/default.nix { };
    stb = pkgs.callPackage ./stb/default.nix { };

    # Generic C++ libraries (header only, no astronomy dependency)
    alea = pkgs.callPackage ./alea/default.nix {
      cudaPackages = null; # host only build, free software, cacheable
    };

    aleaWithCuda = pkgs.callPackage ./alea/default.nix {
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
    wcstools = pkgs.callPackage ./wcstools/default.nix { };
    wcslib = pkgs.callPackage ./wcslib/default.nix { };
    casacore = pkgs.callPackage ./casacore/default.nix {
      openblas = openblasSingleThreaded;
      inherit wcslib;
    };
    aocommon = pkgs.callPackage ./aocommon/default.nix {
      openblas = openblasSingleThreaded;
      inherit casacore;
    };
    schaapcommon = pkgs.callPackage ./schaapcommon/default.nix { inherit aocommon; };
    radler = pkgs.callPackage ./radler/default.nix { inherit aocommon schaapcommon casacore; };
    wsclean = pkgs.callPackage ./wsclean/default.nix {
      inherit
        aocommon
        radler
        schaapcommon
        idg
        ;
      ska-sdp-func = null;
    };
    ska-sdp-func = pkgs.callPackage ./ska-sdp-func/default.nix { };
    xtensor-fftw = pkgs.callPackage ./xtensor-fftw/default.nix { };
    everybeam = pkgs.callPackage ./everybeam/default.nix {
      inherit aocommon schaapcommon ska-sdp-func xtensor-fftw;
    };
    idg = pkgs.callPackage ./idg/default.nix { inherit aocommon schaapcommon; };
    dysco = pkgs.callPackage ./dysco/default.nix { inherit casacore; };

    # Test data shared by the DP3 test suite: the MWA MeasurementSet and a
    # pinned casacore measures snapshot (see test_data/default.nix).
    dp3TestData = pkgs.callPackage ./test_data/default.nix { };
    oskar = pkgs.callPackage ./oskar/default.nix { inherit ska-sdp-func casacore; };
    oskarWithGUI = pkgs.libsForQt5.callPackage ./oskar/default.nix {
      withGUI = true;
      inherit casacore ska-sdp-func;
    };
    aoflagger = pkgs.callPackage ./aoflagger/default.nix { inherit aocommon; };
    pal = pkgs.callPackage ./pal/default.nix { };
    cotter = pkgs.callPackage ./cotter/default.nix {
      inherit
        casacore
        aoflagger
        pal
        ;
    };
    ds9 = pkgs.callPackage ./ds9/default.nix { };

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
    nixgpu = pkgs.callPackage ./nixgpu/default.nix {
      # intel-media-driver only exists on x86; it is simply omitted elsewhere.
      intel-media-driver = if pkgs.stdenv.hostPlatform.isx86 then pkgs.intel-media-driver else null;
    };

    # Small CUDA test program, built hermetically with the Nix CUDA toolkit.
    cuda-hello = pkgs.callPackage ./cuda-hello/default.nix {
      cudaPackages = pkgs.cudaPackages_13_0;
      inherit (astroConfig) cudaArch;
    };

    cyberether = pkgs.callPackage ./cyberether/default.nix {
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
      geodata = pkgs.callPackage ./cyberether/geodata/default.nix { };
    };
  };

  py_astro_pkgs = rec {

    python3Packages = pkgs.python3Packages.overrideScope (final: prev: {
      radler = astro_pkgs.radler.override { pythonBuild = true; };
      xtensor-python = pkgs.callPackage ./xtensor-python/default.nix { };
      mapbox-earcut = pkgs.callPackage ./mapbox-earcut/default.nix {
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
        casacore = astro_pkgs.casacore;
        boost = pkgs.boost.override { enablePython = true; python = pkgs.python3; };
        wcslib = astro_pkgs.wcslib;
        cfitsio = pkgs.cfitsio;
        readline = pkgs.readline;
        # Must match the OpenBLAS linked into casacore (see
        # openblasSingleThreaded above); loading two OpenBLAS variants with
        # the same SONAME but different integer widths would be undefined.
        openblas = astro_pkgs.openblasSingleThreaded;
      };

      meqtrees-cattery = final.callPackage ./meqtrees-cattery/default.nix { };

      # DP3 Python package (pybind11 bindings + DP3.py CLI).  Built through
      # CMake, using the astro-nix casacore/aoflagger/everybeam/idg.
      dp3 = final.callPackage ./dp3/default.nix {
        inherit (astro_pkgs) casacore aoflagger everybeam idg dysco;
        inherit (astro_pkgs.dp3TestData) mwaTestMs casarc;
        openblas = astro_pkgs.openblasSingleThreaded;
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
        src = builtins.fetchGit {
          url = "ssh://git@github.com/cyriltasse/DDFacet";
          ref="refs/heads/HackathonRennes_June26_Adastra";
        };
      });

      killms_dev = (final.callPackage ./killms/dev.nix {
        ddfacet = final.ddfacet_dev;
      }).overrideAttrs (old: {
        src = builtins.fetchGit {
          url = "ssh://git@github.com/cyriltasse/killMS";
          ref="refs/heads/HackathonRennes_June26_Adastra";
        };
      });

      ddf-pipeline = final.callPackage ./ddf-pipeline/default.nix {
        ddfacet = final.ddfacet_dev;
        killms = final.killms_dev;
      };
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
  };

in
let
  pkgSet = pkgs // astro_pkgs // py_astro_pkgs;

  # CyberEther's geodata step (resources/geodata) requires a python with
  # numpy + mapbox_earcut; give the build the full interpreted env.
  cyberetherPython = pkgSet.python3Packages.python.withPackages (ps: [
    pkgSet.python3Packages.numpy
    pkgSet.python3Packages.mapbox-earcut
  ]);

  # Fixed CyberEther (see below); BLADE links against its jetstream library.
  cyberetherFixed = pkgSet.cyberether.override { python3 = cyberetherPython; };
in
pkgSet
// {
  cyberether = cyberetherFixed;
  blade = pkgs.callPackage ./blade/default.nix {
    inherit (pkgSet) meson;
    cyberether = cyberetherFixed;
    libxcb = pkgSet.xorg.libxcb;
  };

}

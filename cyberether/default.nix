# CyberEther 1.9.2 — GPU-accelerated signal processing framework.
#
# Features enabled: Vulkan GUI, Superluminal Python bindings (-Dpython=true),
# SDR stack (SoapySDR/Airspy/HackRF/RTLSDR/LimeSuite), examples, tests.
# `remote` (static GStreamer) and `inference` (ONNX Runtime) are disabled:
# they are heavy upstream subprojects, same scope as the project's own
# native (non-Docker) build notes.
#
# Meson subprojects are resolved fully offline: every source/patch the wrap
# files pin is provided as a Nix derivation (flat namespace siblings of this
# package: fmt glfw glm rapidyaml cpp-httplib nlohmann_json qrencode
# nanobench nanobind robin-map libmodes stb) or bundled inline (catch2,
# nanobench nanobind robin-map libmodes stb) or bundled inline (catch2,
# tree-sitter-*, velopack [optional, disabled via -Dvelopack=disabled], SoapySDR
# stack). zlib, openssl and libusb are exceptions: the loaders use the system
# zlib/openssl via pkg-config, and the SDR subprojects are pointed at the
# system libusb (nixpkgs 1.0.29) through a small meson subproject shim instead
# of building the bundled 1.0.26 copy. All remaining sources are merged into
# MESON_PACKAGE_CACHE_DIR before `meson setup --wrap-mode=nodownload`.
{
  lib,
  stdenv,
  fetchgit,
  fetchurl,
  runCommand,
  meson,
  ninja,
  pkg-config,
  python3,
  glslang,
  vulkan-headers,
  vulkan-loader,
  mesa,
  wayland,
  wayland-scanner,
  wayland-protocols,
  libxkbcommon,
  libglvnd,
  libdrm,
  xorg,
  fmt,
  glfw,
  glm,
  rapidyaml,
  cpp-httplib,
  nlohmann_json,
  qrencode,
  nanobench,
  nanobind,
  robin-map,
  libmodes,
  stb,
  # System zlib (discovered via pkg-config by the patched loader); no bundle.
  zlib,
  # System OpenSSL (discovered via pkg-config by the patched loader); no bundle.
  openssl,
  # Upstream nixpkgs libusb (1.0.29); consumed by the SDR meson subprojects via
  # the `subprojects/libusb` shim instead of the bundled 1.0.26 subproject.
  libusb1,
  geodata,
}:

let
  #
  # Inline subproject bundles (exceptions kept out of the flat namespace:
  # catch2 = tests only, tree-sitter-* and velopack [optional, disabled via
  # -Dvelopack=disabled] = exempted, SDR stack = keep as subproject per request).
  #
  catch2 = fetchurl {
    name = "Catch2-3.4.0.tar.gz";
    url = "https://github.com/catchorg/Catch2/archive/v3.4.0.tar.gz";
    sha256 = "122928b814b75717316c71af69bd2b43387643ba076a6ec16e7882bfb2dfacbb";
  };
  tree-sitter = fetchurl {
    name = "tree-sitter-0.26.3.tar.gz";
    url = "https://github.com/tree-sitter/tree-sitter/archive/refs/tags/v0.26.3.tar.gz";
    sha256 = "7f4a7cf0a2cd217444063fe2a4d800bc9d21ed609badc2ac20c0841d67166550";
  };
  tree-sitter-patch = fetchurl {
    name = "tree-sitter_0.26.3-1_patch.zip";
    url = "https://wrapdb.mesonbuild.com/v2/tree-sitter_0.26.3-1/get_patch";
    sha256 = "268ff355375227f95b816426c8e05f162b7fb8334f9eaa23ce3dcf121e0c9f0a";
  };
  tree-sitter-python = fetchurl {
    name = "tree-sitter-python-0.25.0.tar.gz";
    url = "https://github.com/tree-sitter/tree-sitter-python/releases/download/v0.25.0/tree-sitter-python.tar.gz";
    sha256 = "7bce887eb2f33e94bf74a69645cf5138d4096720e54fd3269a6124c06b93c584";
  };
  tree-sitter-markdown = fetchurl {
    name = "tree-sitter-markdown-0.5.3.tar.gz";
    url = "https://github.com/tree-sitter-grammars/tree-sitter-markdown/releases/download/v0.5.3/tree-sitter-markdown.tar.gz";
    sha256 = "22e40c51810e64c6bf073f0147f3abc167473206789e6dcbed4ba198ff3ca119";
  };
  soapysdr = fetchurl {
    name = "SoapySDR-soapy-sdr-0.8.1.tar.gz";
    url = "https://github.com/pothosware/SoapySDR/archive/refs/tags/soapy-sdr-0.8.1.tar.gz";
    sha256 = "a508083875ed75d1090c24f88abef9895ad65f0f1b54e96d74094478f0c400e6";
  };
  soapyairspy = fetchurl {
    name = "SoapyAirspy-soapy-airspy-0.2.0.tar.gz";
    url = "https://github.com/pothosware/SoapyAirspy/archive/refs/tags/soapy-airspy-0.2.0.tar.gz";
    sha256 = "4279ab4278fab699ef8325f3f921b2307496130a56028d33022be10916b6ccff";
  };
  soapyhackrf = fetchurl {
    name = "SoapyHackRF-soapy-hackrf-0.3.4.tar.gz";
    url = "https://github.com/pothosware/SoapyHackRF/archive/refs/tags/soapy-hackrf-0.3.4.tar.gz";
    sha256 = "c7a1b8aee7af9d9e11e42aa436eae8508f19775cdc8bc52e565a5d7f2e2e43ed";
  };
  soapyrtlsdr = fetchurl {
    name = "SoapyRTLSDR-soapy-rtl-sdr-0.3.3.tar.gz";
    url = "https://github.com/pothosware/SoapyRTLSDR/archive/refs/tags/soapy-rtl-sdr-0.3.3.tar.gz";
    sha256 = "757c3c3bd17c5a12c7168db2f2f0fd274457e65f35e23c5ec9aec34e3ef54ece";
  };
  limesuite = fetchurl {
    name = "LimeSuite-23.11.0.tar.gz";
    url = "https://github.com/myriadrf/LimeSuite/archive/refs/tags/v23.11.0.tar.gz";
    sha256 = "fd8a448b92bc5ee4012f0ba58785f3c7e0a4d342b24e26275318802dfe00eb33";
  };
  libairspy = fetchurl {
    name = "airspyone_host-1.0.10.tar.gz";
    url = "https://github.com/airspy/airspyone_host/archive/refs/tags/v1.0.10.tar.gz";
    sha256 = "fcca23911c9a9da71cebeffeba708c59d1d6401eec6eb2dd73cae35b8ea3c613";
  };
  libhackrf = fetchurl {
    name = "hackrf-2026.01.3.tar.gz";
    url = "https://github.com/greatscottgadgets/hackrf/archive/refs/tags/v2026.01.3.tar.gz";
    sha256 = "48238f3a21189fa8cbe67838584cc045b9e5433767db8c9c30c1da02a1489f2c";
  };
  librtlsdr = fetchurl {
    name = "librtlsdr-1261fbb285297da08f4620b18871b6d6d9ec2a7b.zip";
    url = "https://github.com/steve-m/librtlsdr/archive/1261fbb285297da08f4620b18871b6d6d9ec2a7b.zip";
    sha256 = "79925da4e274b87a98e5364459e0e3faf346bd56dfcb7d38fa089e5cc6785797";
  };
  mkBundle =
    { name, files }:
    runCommand name { } ''
      mkdir -p $out
      ${lib.concatStringsSep "\n" (map (f: "ln -s ${f.src} $out/${f.cacheName}") files)}
    '';

  inlineBundles = [
    (mkBundle {
      name = "catch2-subproject-bundle";
      files = [
        {
          src = catch2;
          cacheName = "Catch2-3.4.0.tar.gz";
        }
      ];
    })
    (mkBundle {
      name = "tree-sitter-subproject-bundle";
      files = [
        {
          src = tree-sitter;
          cacheName = "tree-sitter-0.26.3.tar.gz";
        }
        {
          src = tree-sitter-patch;
          cacheName = "tree-sitter_0.26.3-1_patch.zip";
        }
      ];
    })
    (mkBundle {
      name = "tree-sitter-python-subproject-bundle";
      files = [
        {
          src = tree-sitter-python;
          cacheName = "tree-sitter-python-0.25.0.tar.gz";
        }
      ];
    })
    (mkBundle {
      name = "tree-sitter-markdown-subproject-bundle";
      files = [
        {
          src = tree-sitter-markdown;
          cacheName = "tree-sitter-markdown-0.5.3.tar.gz";
        }
      ];
    })
    (mkBundle {
      name = "soapysdr-subproject-bundle";
      files = [
        {
          src = soapysdr;
          cacheName = "SoapySDR-soapy-sdr-0.8.1.tar.gz";
        }
      ];
    })
    (mkBundle {
      name = "soapyairspy-subproject-bundle";
      files = [
        {
          src = soapyairspy;
          cacheName = "SoapyAirspy-soapy-airspy-0.2.0.tar.gz";
        }
      ];
    })
    (mkBundle {
      name = "soapyhackrf-subproject-bundle";
      files = [
        {
          src = soapyhackrf;
          cacheName = "SoapyHackRF-soapy-hackrf-0.3.4.tar.gz";
        }
      ];
    })
    (mkBundle {
      name = "soapyrtlsdr-subproject-bundle";
      files = [
        {
          src = soapyrtlsdr;
          cacheName = "SoapyRTLSDR-soapy-rtl-sdr-0.3.3.tar.gz";
        }
      ];
    })
    (mkBundle {
      name = "limesuite-subproject-bundle";
      files = [
        {
          src = limesuite;
          cacheName = "LimeSuite-23.11.0.tar.gz";
        }
      ];
    })
    (mkBundle {
      name = "libairspy-subproject-bundle";
      files = [
        {
          src = libairspy;
          cacheName = "airspyone_host-1.0.10.tar.gz";
        }
      ];
    })
    (mkBundle {
      name = "libhackrf-subproject-bundle";
      files = [
        {
          src = libhackrf;
          cacheName = "hackrf-2026.01.3.tar.gz";
        }
      ];
    })
    (mkBundle {
      name = "librtlsdr-subproject-bundle";
      files = [
        {
          src = librtlsdr;
          cacheName = "librtlsdr-1261fbb285297da08f4620b18871b6d6d9ec2a7b.zip";
        }
      ];
    })
  ];

  # All bundles merged into the meson wrap cache (files and extracted dirs).
  allBundles = [
    fmt
    glfw
    glm
    rapidyaml
    cpp-httplib
    nlohmann_json
    qrencode
    nanobench
    nanobind
    robin-map
    libmodes
    stb
  ]
  ++ inlineBundles;

in
stdenv.mkDerivation {
  pname = "cyberether";
  version = "1.9.2";

  src = fetchgit {
    url = "https://github.com/luigifcruz/cyberether.git";
    rev = "a8e4bee00be1977f44eee453f3f8b55b999b4b03"; # v1.9.2
    sha256 = "sha256-YyPrFueGifaV9eAzwEHGwMd9uM0UAamWVx30SxXYMBk=";
  };

  # Upstream compiles cpp-httplib as an LTO static archive, which cannot be
  # resolved when the consumer links without the GCC LTO plugin (Nix binutils
  # does not auto-load it). Also: `find_installation()` with no argument binds
  # meson's own runtime python, which lacks numpy/mapbox_earcut; look up
  # `python3` on PATH so the env python (with those modules) is used.
  patches = [
    ./patches/000-cpp-httplib-no-lto.patch
    ./patches/001-find-python3.patch
    ./patches/002-use-system-zlib.patch
    ./patches/003-disable-velopack.patch
    ./patches/004-use-system-openssl.patch
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
    glslang
    wayland-scanner
    wayland-protocols
  ];

  buildInputs = [
    vulkan-headers
    vulkan-loader
    libxkbcommon
    libglvnd
    libdrm
    wayland
    xorg.libX11
    xorg.libXext
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXcursor
    xorg.libXi
    xorg.libXxf86vm
    xorg.libxcb
    xorg.xorgproto
    mesa
    # System zlib for the patched zlib loader (pkg-config).
    zlib
    # System OpenSSL for the patched openssl/cpp-httplib loaders (pkg-config).
    openssl
    # Upstream libusb for the SDR meson subprojects (see the shim below).
    libusb1
  ];

  enableParallelBuilding = true;

  # Meson now keeps every /nix/store entry the linker (ld-wrapper) put in
  # DT_RPATH/DT_RUNPATH, including entries it classifies as build-only
  # (see meson/008-keep-nix-store-rpath.patch). Nixpkgs' fixupPhase would
  # otherwise run `patchelf --shrink-rpath` and drop the store directories
  # that are not direct DT_NEEDED dependencies (GLFW dlopen()s X11/Wayland
  # and the Vulkan loader, so those libraries are intentionally absent from
  # DT_NEEDED). Opt out of that stripping so the RUNPATH produced by meson
  # survives into the final output.
  dontPatchELF = true;

  # The meson buildInput ships a setup-hook that would install its own
  # mesonConfigurePhase and run `meson setup` with nixpkgs defaults (without
  # our MESON_PACKAGE_CACHE_DIR). Own the configure step so buildPhase below
  # is the single meson driver.
  configurePhase = "true";

  buildPhase = ''
    runHook preBuild

    # --- offline geodata ---------------------------------------------------
    # Natural Earth GeoJSON is not tracked by CyberEther (downloaded from
    # cdn.cyberether.org at build time); provide the pinned bundle.
    cp -rL ${geodata}/resources/. resources/

    # --- offline meson wrap cache -----------------------------------------
    # The zlib and openssl subproject wraps are dropped: their loaders now use
    # the system libraries via pkg-config (see patches/002-use-system-zlib.patch
    # and patches/004-use-system-openssl.patch).
    rm -f subprojects/zlib.wrap subprojects/openssl.wrap

    # --- system libusb ----------------------------------------------------
    # libhackrf/librtlsdr/libairspy/limesuite all call
    # `subproject('libusb').get_variable('libusb_dep')`. Drop the bundled
    # 1.0.26 wrap and install the local shim subproject (libusb-shim/) that
    # forwards that variable to the upstream nixpkgs libusb (1.0.29) through
    # pkg-config.
    rm -f subprojects/libusb.wrap
    mkdir -p subprojects/libusb
    install -m 644 ${./libusb-shim}/meson.build \
      ${./libusb-shim}/meson_options.txt subprojects/libusb/

    export MESON_PACKAGE_CACHE_DIR="$(pwd)/meson-cache"
    mkdir -p "$MESON_PACKAGE_CACHE_DIR"
    for b in ${toString allBundles}; do
      for f in "$b"/*; do
        ln -sfn "$f" "$MESON_PACKAGE_CACHE_DIR/$(basename "$f")"
      done
    done

    meson setup build \
      --prefix="$out" \
      --wrap-mode=nodownload \
      --default-library=shared \
      -Dpython=true \
      -Dremote=disabled \
      -Dinference=disabled \
      -Dvelopack=disabled \
      -Dtests=true \
      -Dexamples=true

    meson compile -C build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    meson install -C build --no-rebuild

    # --- examples ----------------------------------------------------------
    # Upstream declares them install:false; bundle them for the CLI/run path.
    mkdir -p "$out/share/cyberether"
    cp -r examples "$out/share/cyberether/examples"
    chmod -R u+w "$out/share/cyberether/examples"

    runHook postInstall
  '';

  meta = with lib; {
    description = "CyberEther - multi-platform GPU-accelerated signal processing framework (Vulkan GUI + Superluminal Python bindings + SoapySDR)";
    homepage = "https://cyberether.org";
    license = licenses.mit;
    mainProgram = "cyberether";
    maintainers = with maintainers; [ ];
  };
}

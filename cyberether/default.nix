# CyberEther 1.11.0 — GPU-accelerated signal processing framework.
#
# Features enabled: Vulkan GUI, Superluminal Python bindings (-Dpython=true),
# SDR stack (SoapySDR/Airspy/HackRF/RTLSDR/LimeSuite/bladeRF), examples, tests.
# `remote` (static GStreamer) and `inference` (ONNX Runtime) are disabled:
# they are heavy upstream subprojects, same scope as the project's own
# native (non-Docker) build notes.
#
# Meson subprojects are resolved fully offline: every source/patch the wrap
# files pin is provided as a Nix derivation (flat namespace siblings of this
# package: glfw glm rapidyaml cpp-httplib nlohmann_json nanobench nanobind
# robin-map libmodes stb) or bundled inline (catch2, tree-sitter-*,
# velopack [optional, disabled via -Dvelopack=disabled]). zlib, openssl,
# libqrencode, fmt, toml++ and the whole SDR stack are exceptions: the loaders
# use Nixpkgs' zlib/openssl/libqrencode/fmt/toml++ through pkg-config, and
# SoapySDR (with its driver plugins) is taken from Nixpkgs and loaded at runtime
# by the patched soapy loader (008-use-system-soapysdr.patch). All remaining
# sources are merged into MESON_PACKAGE_CACHE_DIR before
# `meson setup --wrap-mode=nodownload`.
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
  # System fmt (libfmt), discovered by the patched fmt loader via pkg-config.
  fmt,
  glfw,
  glm,
  rapidyaml,
  cpp-httplib,
  nlohmann_json,
  nanobench,
  nanobind,
  robin-map,
  libmodes,
  stb,
  # System zlib (discovered via pkg-config by the patched loader); no bundle.
  zlib,
  # System OpenSSL (discovered via pkg-config by the patched loader); no bundle.
  openssl,
  # System libqrencode (4.1.1, discovered via pkg-config by the patched
  # loader); no bundle.
  qrencode,
  # System toml++ (3.4.0, discovered by the patched loader via pkg-config);
  # no bundle (wrapdb no longer serves the patch that turns the upstream
  # tarball into a meson subproject).
  tomlplusplus,
  # Nixpkgs' SoapySDR, joined with the SDR driver plugins (airspy, bladeRF,
  # HackRF, Lime, rtlsdr) through `soapysdr.override { extraPackages = ...; }`
  # so that SoapySDR discovers them at runtime (see the patched soapy loader).
  soapysdr,
  geodata,
}:

let
  #
  # Inline subproject bundles (kept out of the flat namespace: catch2 = tests
  # only, tree-sitter-* = release tarballs, velopack = optional, disabled via
  # -Dvelopack=disabled). The whole SDR stack comes from Nixpkgs (see
  # `soapysdr`), so no soapy/limesuite/rtlsdr/airspy sources are bundled.
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
  ];

  # All bundles merged into the meson wrap cache (files and extracted dirs).
  allBundles = [
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
  ]
  ++ inlineBundles;

in
stdenv.mkDerivation {
  pname = "cyberether";
  version = "1.11.0";

  src = fetchgit {
    url = "https://github.com/luigifcruz/cyberether.git";
    rev = "3f2d659ac47fd911d14f048787660ba39b9282c2"; # v1.11.0
    sha256 = "sha256-t/tlszI5ENlnD2Ly3oyi0K3ywgyaJ91iA+bnjGcNz6w=";
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
    ./patches/005-use-system-qrencode.patch
    ./patches/006-use-system-fmt.patch
    ./patches/007-use-system-tomlplusplus.patch
    ./patches/008-use-system-soapysdr.patch
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
    # System libqrencode for the patched qrencode loader (pkg-config).
    qrencode
    # System fmt (libfmt) for the patched fmt loader (pkg-config).
    fmt
    # System toml++ for the patched tomlplusplus loader (pkg-config).
    tomlplusplus
    # SoapySDR joined with the SDR driver plugins (see the patched soapy
    # loader); the plugins are picked up by SoapySDR at runtime.
    soapysdr
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
    # The zlib, openssl, qrencode, fmt and tomlplusplus subproject wraps are
    # dropped: their loaders use the system libraries via pkg-config (see
    # patches 002-use-system-zlib.patch, 004-use-system-openssl.patch,
    # 005-use-system-qrencode.patch, 006-use-system-fmt.patch and
    # 007-use-system-tomlplusplus.patch).
    rm -f subprojects/zlib.wrap subprojects/openssl.wrap \
      subprojects/qrencode.wrap subprojects/fmt.wrap \
      subprojects/tomlplusplus.wrap

    # --- system SoapySDR ---------------------------------------------------
    # The patched soapy loader uses the system SoapySDR + its plugin modules
    # (patch 008-use-system-soapysdr.patch); the bundled soapysdr and
    # SoapySDR-driver subprojects, and therefore the libusb/libhackrf shims
    # they needed, are gone. Their wraps are inert but harmless; drop them so
    # `--wrap-mode=nodownload` never has to consider them.
    rm -f subprojects/soapysdr.wrap subprojects/soapyairspy.wrap \
      subprojects/soapyhackrf.wrap subprojects/soapyrtlsdr.wrap \
      subprojects/limesuite.wrap subprojects/libairspy.wrap \
      subprojects/librtlsdr.wrap subprojects/soapybladerf.wrap \
      subprojects/libbladerf.wrap subprojects/bladerf-no-os.wrap \
      subprojects/libusb.wrap subprojects/libhackrf.wrap

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

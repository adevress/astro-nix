# CyberEther 2.0.0 — GPU-accelerated signal processing framework.
#
# Features enabled: Vulkan GUI, Superluminal Python bindings (-Dpython=true),
# the native SDR stack (BirriaSDR/RTLSDR/Airspy/AirspyHF/HackRF/LimeSDR-NG/
# bladeRF/PlutoSDR), examples and tests.
#
# Optional heavy subprojects are disabled explicitly:
#   * `remote`   (bundled static GStreamer: glib/libffi/pcre2/libnice/vpx/...)
#   * `inference` (ONNX Runtime)
#   * `terminal`  (libghostty-vt, which requires a Zig compiler)
#   * `velopack`  (prebuilt auto-updater blob; see
#     patches/003-disable-velopack.patch)
#
# Meson subprojects are resolved fully offline. Every source/patch the wrap
# files pin is provided by `mesonSubprojectCache` below (flat namespace in
# MESON_PACKAGE_CACHE_DIR) or bundled inline (the nanobind source directory is
# shipped pre-extracted so its `#!/usr/bin/env python3` version script works in
# the sandbox). The following subprojects are deliberately not bundled and are
# instead taken from Nixpkgs through the patched loaders:
#   * zlib        (002-use-system-zlib.patch, pkg-config)
#   * openssl     (004-use-system-openssl.patch, pkg-config)
#   * qrencode    (005-use-system-qrencode.patch, pkg-config)
#   * toml++      (007-use-system-tomlplusplus.patch, pkg-config)
#   * fmt         (006-use-system-fmt.patch, pkg-config)
#   * glfw        (008-use-system-glfw.patch, pkg-config)
#   * glm         (011-use-system-glm.patch, pkg-config)
#   * rapidyaml   (012-use-system-rapidyaml.patch, CMake package config)
#   * nlohmann_json (013-use-system-nlohmann-json.patch, pkg-config)
#   * libzmq      (014-use-system-libzmq.patch, pkg-config)
#   * cpp-httplib (015-use-system-httplib.patch, pkg-config)
#   * nanobench   (016-use-system-nanobench.patch, CMake package config)
#   * stb         (017-use-system-stb.patch, pkg-config)
#   * miniz       (018-use-system-miniz.patch, pkg-config)
#   * miniaudio   (019-use-system-miniaudio.patch, pkg-config)
#   * tree-sitter and its grammars (020-use-system-tree-sitter.patch,
#                  pkg-config + prebuilt grammar shared objects)
#   * Catch2      (021-use-system-catch2.patch, pkg-config)
#   * RTLSDR/Airspy/AirspyHF/HackRF/bladeRF/PlutoSDR
#                 (022-use-system-sdr.patch, pkg-config)
#   * libusb      (023-use-system-libusb.patch, for the two embedded SDR
#                  vendors; pkg-config)
#   * robin-map   (024-use-system-robin-map.patch, CMake package config for
#                  the embedded nanobind subproject)
#   * pocketfft   (025-use-system-pocketfft.patch, astro-nix package)
#   * LimeSuiteNG (022-use-system-sdr.patch, astro-nix package)
#
# Only the dependencies that are not packaged in Nixpkgs remain embedded:
# nanobind, libmodes and BirriaSDR.
{
  lib,
  stdenv,
  fetchgit,
  fetchurl,
  runCommand,
  git,
  cmake,
  meson,
  ninja,
  pkg-config,
  python3,
  glslang,
  fmt,
  glfw,
  glm,
  rapidyaml,
  nlohmann_json,
  zeromq,
  httplib,
  nanobench,
  robin-map,
  stb,
  miniz,
  miniaudio,
  alsa-lib,
  libpulseaudio,
  libjack2,
  sndio,
  libvorbis,
  opusfile,
  tree-sitter,
  tree-sitter-grammars,
  catch2_3,
  rtlsdr,
  airspy,
  airspyhf,
  hackrf,
  libbladeRF,
  libad9361,
  libiio,
  libusb1,
  pocketfft,
  limesuiteng,
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
  # System libraries reached through the patched pkg-config loaders.
  zlib,
  openssl,
  qrencode,
  tomlplusplus,
  # Offline geodata bundle (resources/geodata/fetch.py cache entry).
  geodata,
}:

let
  # fetch.py looks the archive up as `<manifest sha256>.bin` in its cache dir.
  geodataCacheName = "d4b613a015c961580dd4a030f7f5dec31330820334656010d767eaef6c049412.bin";

  # Sources and wrapdb patch archives pinned by upstream's subprojects/*.wrap.
  # Keeping the upstream filename is required: meson looks the exact
  # `source_filename` / `patch_filename` up in MESON_PACKAGE_CACHE_DIR.
  subprojectSources = [
    {
      file = "nanobind-2.12.0.tar.gz";
      url = "https://github.com/wjakob/nanobind/archive/refs/tags/v2.12.0.tar.gz";
      hash = "01f1f0cd0398743c18f33d07ae36ad410bd7f4a1e90683b508504de897d6e629";
    }
    {
      file = "nanobind_2.12.0-1_patch.zip";
      url = "https://wrapdb.mesonbuild.com/v2/nanobind_2.12.0-1/get_patch";
      hash = "4b8158bdb359218bcfb7a5b4459fbfa5919171d9ea2400de3a84cf9ab7c7308b";
    }
    # Not packaged in Nixpkgs: keep the pinned BirriaSDR subproject.
    {
      file = "BirriaSDR-8ddab14ccc4dde0787bc0db84647dfbb6dca6585.tar.gz";
      url = "https://github.com/luigifcruz/BirriaSDR/archive/8ddab14ccc4dde0787bc0db84647dfbb6dca6585.tar.gz";
      hash = "4746b1372326b233f5cb29808c7ede895630c817d3fc17530a07b628875b938e";
    }
  ];

  # wrap-git subprojects: meson expects an already-extracted directory whose
  # name matches the `directory` entry of the wrap file.
  libmodesSrc = fetchgit {
    url = "https://github.com/watson/libmodes.git";
    rev = "e82c6faedd21ced7fd1c2808c0d9e9ffbb8c0ed6";
    sha256 = "sha256-brU6IYHcCJbArYf4DMyj3DfKp2unsjZq+IaM5M1pK1I=";
  };
  nanobindSrc = fetchurl {
    name = "nanobind-2.12.0.tar.gz";
    url = "https://github.com/wjakob/nanobind/archive/refs/tags/v2.12.0.tar.gz";
    sha256 = "01f1f0cd0398743c18f33d07ae36ad410bd7f4a1e90683b508504de897d6e629";
  };

  mesonSubprojectCache =
    runCommand "cyberether-meson-subproject-cache"
      {
        nativeBuildInputs = [ python3 ];
      }
      ''
        mkdir -p $out
        ${lib.concatMapStringsSep "\n" (
          source:
          "ln -s ${
            fetchurl {
              name = source.file;
              url = source.url;
              sha256 = source.hash;
            }
          } $out/${source.file}"
        ) subprojectSources}

        # wrap-git sources: provide the extracted checkout directly.
        mkdir -p $out/libmodes
        cp -rL ${libmodesSrc}/. $out/libmodes/

        # nanobind runs src/version.py through its `/usr/bin/env python3`
        # shebang during configure; /usr/bin/env does not exist in the sandbox.
        # (The archive itself is symlinked above via subprojectSources.)
        mkdir work
        tar xzf ${nanobindSrc} -C work
        sed -i "1s|.*|#!${python3}/bin/python3|" work/nanobind-2.12.0/src/version.py
        chmod +x work/nanobind-2.12.0/src/version.py
        cp -r work/nanobind-2.12.0 $out/
      '';

in
stdenv.mkDerivation {
  pname = "cyberether";
  version = "2.0.0";

  src = fetchgit {
    url = "https://github.com/luigifcruz/cyberether.git";
    rev = "db99f6144c4a065a0b7280a721f0c409fff653d0"; # v2.0.0
    sha256 = "sha256-3RxY3AnY4vSkSMOrdbhShClYwava2tre3tz27ooSZvs=";
  };

  # 001: make the build-time Python installation explicit (avoids picking up
  #      meson's own interpreter instead of the injected python3).
  # 002/004/005/007: use the Nixpkgs zlib/openssl/qrencode/toml++ through
  #      pkg-config instead of building the pinned static subprojects.
  # 003: make the prebuilt Velopack updater opt-out; the Nix build disables it.
  patches = [
    ./patches/001-find-python3.patch
    ./patches/002-use-system-zlib.patch
    ./patches/003-disable-velopack.patch
    ./patches/004-use-system-openssl.patch
    ./patches/005-use-system-qrencode.patch
    ./patches/006-use-system-fmt.patch
    ./patches/007-use-system-tomlplusplus.patch
    ./patches/008-use-system-glfw.patch
    ./patches/011-use-system-glm.patch
    ./patches/012-use-system-rapidyaml.patch
    ./patches/013-use-system-nlohmann-json.patch
    ./patches/014-use-system-libzmq.patch
    ./patches/015-use-system-httplib.patch
    ./patches/016-use-system-nanobench.patch
    ./patches/017-use-system-stb.patch
    ./patches/018-use-system-miniz.patch
    ./patches/019-use-system-miniaudio.patch
    ./patches/020-use-system-tree-sitter.patch
    ./patches/021-use-system-catch2.patch
    ./patches/022-use-system-sdr.patch
    ./patches/023-use-system-libusb.patch
    ./patches/024-use-system-robin-map.patch
    ./patches/025-use-system-pocketfft.patch
  ];

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    cmake
    python3
    glslang
    wayland-scanner
    wayland-protocols
    git
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
    zlib
    openssl
    qrencode
    tomlplusplus
    fmt
    glfw
    glm
    rapidyaml
    nlohmann_json
    zeromq
    httplib
    nanobench
    robin-map
    stb
    miniz
    # miniaudio ships its header/pkg-config in the `dev` output and the shared
    # library in `out`.
    (lib.getDev miniaudio)
    (lib.getLib miniaudio)
    alsa-lib
    libpulseaudio
    libjack2
    sndio
    libvorbis
    opusfile
    tree-sitter
    catch2_3
    rtlsdr
    airspy
    airspyhf
    hackrf
    libbladeRF
    libad9361
    # libiio ships its headers/.pc in the `dev` output and the shared library
    # in the `lib` output.
    (lib.getDev libiio)
    (lib.getLib libiio)
    libusb1
    pocketfft
    limesuiteng
  ];

  # Meson keeps every /nix/store entry the linker (ld-wrapper) put in
  # DT_RPATH/DT_RUNPATH, including entries it classifies as build-only
  # (see meson/008-keep-nix-store-rpath.patch). Nixpkgs' fixupPhase would
  # otherwise run `patchelf --shrink-rpath` and drop the store directories
  # that are not direct DT_NEEDED dependencies (GLFW dlopen()s X11/Wayland
  # and the Vulkan loader), so opt out of that stripping.
  dontPatchELF = true;

  # Produce the `debug` output with the DWARF info of libjetstream and the
  # `cyberether` executable.
  separateDebugInfo = true;

  # BirriaSDR is memory-hungry when compiled; serialise the build so smaller
  # builders are not OOM-killed (the Nixpkgs ninja hook then runs `ninja -j1`).
  enableParallelBuilding = false;

  # Release build; the Nixpkgs meson hook defaults to `--buildtype=plain`. The
  # hook also passes `-Dwrap_mode=nodownload`, so only the cached subprojects
  # below can be resolved.
  mesonBuildType = "debugoptimized";

  mesonFlags = [
    "--default-library=shared"
    "-Dtree-sitter-grammars=${tree-sitter-grammars}"
    "-Dpython=true"
    "-Dremote=disabled"
    "-Dinference=disabled"
    "-Dterminal=disabled"
    "-Dvelopack=disabled"
    "-Dtests=true"
    "-Dexamples=true"
  ];

  # `meson setup` (run by the Nixpkgs meson hook) resolves the wrap files and
  # reads MESON_PACKAGE_CACHE_DIR, so the offline caches and the wrapper edits
  # must happen before the configure phase. This cannot live in `preBuild`:
  # that hook runs after `meson setup`, when the wraps have already been read.
  preConfigure = ''
    # --- offline geodata ---------------------------------------------------
    # resources/geodata/fetch.py downloads a precompiled map bundle from
    # cdn.cyberether.org at build time. Seed its cache with the pinned file so
    # the checksum matches and no network access is attempted.
    mkdir -p .cache/geodata
    ln -s ${geodata} ".cache/geodata/${geodataCacheName}"

    # --- offline meson wrap cache -----------------------------------------
    # Every dependency that is available in Nixpkgs is provided through the
    # patches above; drop the corresponding wraps so `--wrap-mode=nodownload`
    # never considers them. Only the embedded subprojects keep their wraps.
    rm -f subprojects/zlib.wrap subprojects/openssl.wrap \
      subprojects/qrencode.wrap subprojects/tomlplusplus.wrap \
      subprojects/fmt.wrap subprojects/glfw.wrap subprojects/glm.wrap \
      subprojects/rapidyaml.wrap subprojects/nlohmann_json.wrap \
      subprojects/libzmq.wrap subprojects/catch2.wrap \
      subprojects/cpp-httplib.wrap subprojects/nanobench.wrap \
      subprojects/robin-map.wrap subprojects/stb.wrap subprojects/miniz.wrap \
      subprojects/miniaudio.wrap subprojects/tree-sitter.wrap \
      subprojects/tree-sitter-python.wrap subprojects/tree-sitter-markdown.wrap \
      subprojects/tree-sitter-yaml.wrap subprojects/tree-sitter-bash.wrap \
      subprojects/tree-sitter-cpp.wrap subprojects/tree-sitter-json.wrap \
      subprojects/librtlsdr.wrap subprojects/libairspy.wrap \
      subprojects/libairspyhf.wrap subprojects/libhackrf.wrap \
      subprojects/libbladerf.wrap subprojects/libad9361.wrap \
      subprojects/libiio.wrap subprojects/libxml2.wrap subprojects/libusb.wrap \
      subprojects/libusb-browser.wrap subprojects/bladerf-no-os.wrap \
      subprojects/pocketfft.wrap subprojects/limesuiteng.wrap \
      subprojects/velopack.wrap

    export MESON_PACKAGE_CACHE_DIR="$(pwd)/meson-cache"
    mkdir -p "$MESON_PACKAGE_CACHE_DIR"
    cp -a ${mesonSubprojectCache}/. "$MESON_PACKAGE_CACHE_DIR/"
  '';

  # The Nixpkgs meson hook drives `meson install`; subproject artefacts are
  # linked against the system libraries and must not be installed alongside.
  mesonInstallFlags = [ "--skip-subprojects" ];

  # The meson hook leaves us in the build directory, hence `../examples`.
  postInstall = ''
    # --- examples ----------------------------------------------------------
    # Upstream declares them install:false; bundle them for the CLI/run path.
    mkdir -p "$out/share/cyberether"
    cp -r ../examples "$out/share/cyberether/examples"
    chmod -R u+w "$out/share/cyberether/examples"
  '';

  doCheck = true;

  # The full test suite needs a Vulkan device (headless builders have none), so
  # run the GPU-independent slice: the shader parser plus the core suites that
  # only touch memory/tools/serialization/settings/platform. The platform
  # `[process]` cases shell out to `/bin/sh` and `/bin/cat`, which do not exist
  # in the build sandbox, so they are excluded.
  checkPhase = ''
    runHook preCheck

    # The meson hook leaves us in the build directory.
    meson test --print-errorlogs shader-parser

    meson test --print-errorlogs --test-args "~[process]" \
      core-memory core-tools core-serialization core-settings core-platform

    runHook postCheck
  '';

  meta = with lib; {
    description = "CyberEther - multi-platform GPU-accelerated signal processing framework (Vulkan GUI + Superluminal Python bindings + SDR stack)";
    homepage = "https://cyberether.org";
    license = licenses.mit;
    mainProgram = "cyberether";
    maintainers = with maintainers; [ ];
  };
}

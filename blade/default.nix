# BLADE 2.0.0-dev — Breakthrough Listen Accelerated DSP Engine.
#
# Jetstream (CyberEther) DSP plugin for radio telescopes (Allen Telescope
# Array). Builds the CPU device implementation (`-Ddevices=cpu`); CUDA support
# is intentionally off so the package builds on machines without a GPU or the
# (unfree) CUDA toolkit, matching this repo's CPU-only posture (cf. oskar's
# `-DFIND_CUDA=OFF`). Enable it by overriding `devices` and adding
# cudaPackages to the inputs.
#
# The build produces a `blade.cep` bundle (plugin module + examples +
# manifest) that CyberEther loads; `meson install` installs nothing itself,
# so installPhase copies the bundle into `$out/share/blade`.
#
# Meson subprojects are resolved fully offline:
# - `jetstream` comes from this repo's `cyberether` package (system
#   dependency via pkg-config, so the `cyberether.wrap` fallback is dropped).
# - `radiointerferometryc99` (always built via `subproject()`, wrap-git) and
#   `erfa` (its static dependency, wrap-git) cannot be served from the meson
#   package cache, so their pinned checkouts are pre-seeded into
#   `subprojects/` in postPatch and the leftover `.wrap` files removed.
# - `catch2` (tests only) is unused: `-Dtests=false`, like idg's
#   `-DBUILD_TESTING=OFF`.
{
  lib,
  stdenv,
  fetchgit,
  meson,
  ninja,
  pkg-config,
  python3,
  cyberether,
  fmt,
  vulkan-headers,
  vulkan-loader,
  libxcb,
}:

let
  # Pinned to subprojects/radiointerferometryc99.wrap @ BLADE rev below.
  radiointerferometryc99Src = fetchgit {
    url = "https://github.com/MydonSolutions/radiointerferometryc99.git";
    rev = "f8f7aa8ca2b9ba13a958c23f21a0faf04cc93ebc";
    sha256 = "sha256-aX9toZzYKhuHraSqUkchq96eeIYCIRBQ37U1R4KuLIo=";
  };
  # Pinned to subprojects/erfa.wrap (v2.0.1) @ BLADE rev below.
  erfaSrc = fetchgit {
    url = "https://github.com/liberfa/erfa.git";
    rev = "9915ba38c9365f8b0738269b8c2ac1fdd5f8dee3"; # v2.0.1
    sha256 = "sha256-NtHYgiN5mo3kWC2H+5TUDbU1nFrwuhNyOIhg2jZbssM=";
  };
in
stdenv.mkDerivation {
  pname = "blade";
  # One commit past v2.0.0-beta7 (7c07e3b "fix(dsp): correct CUDA validation
  # and channelizer diagnostics", 2026-08-21).
  version = "2.0.0-dev";

  src = fetchgit {
    url = "https://github.com/luigifcruz/blade.git";
    rev = "7c07e3b238587ddc9c6e076195a6a70858f07e5c";
    sha256 = "sha256-gD/GxjStzS8/UOJghmjMlg4V3XUvIIijNv08aWvNy0E=";
    fetchSubmodules = false;
  };

  nativeBuildInputs = [
    meson
    ninja
    pkg-config
    python3
  ];

  buildInputs = [
    # Provides the `jetstream` dependency (>= 1.9.0) via pkg-config.
    cyberether
    # System fmt (libfmt): jetstream headers include <fmt/*.h> but
    # cyberether does not propagate it (cf. its 006-use-system-fmt.patch).
    fmt
    # `jetstream.pc` Requires vulkan; provide its .pc/headers so meson's
    # `dependency('jetstream')` resolves (same inputs cyberether builds with).
    vulkan-headers
    vulkan-loader
    # jetstream headers (vulkan backend) include <xcb/xcb.h>; provide XCB
    # headers for compilation.
    libxcb
  ];

  enableParallelBuilding = true;

  postPatch = ''
    # --- offline meson subprojects ---------------------------------------
    # Seed the wrap-git checkouts (meson uses an existing subprojects/<dir>
    # as-is, without consulting the network), covering both the top-level
    # lookups and radiointerferometryc99's nested `dependency('erfa')`.
    rm -rf subprojects/radiointerferometryc99 subprojects/erfa
    cp -r ${radiointerferometryc99Src} subprojects/radiointerferometryc99
    chmod -R u+w subprojects/radiointerferometryc99
    cp -r ${erfaSrc} subprojects/erfa
    chmod -R u+w subprojects/erfa
    mkdir -p subprojects/radiointerferometryc99/subprojects
    cp -r ${erfaSrc} subprojects/radiointerferometryc99/subprojects/erfa
    chmod -R u+w subprojects/radiointerferometryc99/subprojects/erfa

    # All remaining wraps are superseded: jetstream comes from the system
    # (cyberether input), catch2 is only needed with -Dtests=true.
    rm -f subprojects/*.wrap
  '';

  # The meson buildInput ships a setup-hook that would run `meson setup` with
  # nixpkgs defaults (networked wrap mode). Own the configure step so
  # buildPhase below is the single meson driver (same as cyberether).
  configurePhase = "true";

  buildPhase = ''
    runHook preBuild

    meson setup build \
      --prefix="$out" \
      --wrap-mode=nodownload \
      -Dtests=false \
      -Ddevices=cpu

    meson compile -C build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    meson install -C build --no-rebuild --skip-subprojects

    # Upstream marks every target install:false; the build-by-default
    # `blade.cep` bundle is the distributable artifact CyberEther loads.
    mkdir -p "$out/share/blade"
    cp build/blade.cep "$out/share/blade/"

    runHook postInstall
  '';

  meta = with lib; {
    description = "BLADE - Breakthrough Listen Accelerated DSP Engine (CyberEther/Jetstream plugin, CPU devices)";
    homepage = "https://github.com/luigifcruz/blade";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}

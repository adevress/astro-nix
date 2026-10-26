# Tracy — real-time, nanosecond-resolution frame profiler
#
# Builds the full Tracy tool set from a pinned upstream release:
#
#   * tracy             — GUI profiler (live mode, record & review)
#   * tracy-capture     — headless live capture CLI
#   * tracy-csvexport   — export a trace to CSV
#   * tracy-import-*    — import Chrome / Fuchsia traces
#   * tracy-update      — offline symbol resolution
#
# The shared Tracy client library and its headers (CPU + GPU instrumentation
# backends) are installed as well, so applications can be instrumented with
# `#include <tracy/Tracy.hpp>` (CPU) or one of the GPU headers, e.g.
# `#include <tracy/TracyCUDA.hpp>`, `TracyVulkan.hpp`, `TracyOpenGL.hpp`,
# `TracyOpenCL.hpp`.
#
# GPU profiling
# -------------
# `withGpu = true` pulls the GPU SDK headers into the propagated inputs so the
# installed client headers can be used for GPU instrumentation, and enables the
# AMD ROCm `rocprofiler-sdk` backend when a package is supplied through
# `rocprofiler-sdk`. GPU zones reported by the instrumented application are
# always displayed by the profiler regardless of this switch; the option only
# affects which backends the client headers can be compiled against.
#
# Version note: 0.13.1 is the newest release whose dependency set matches the
# pinned nixpkgs (25.11) closely enough to be devendored safely. Bumping to a
# newer upstream release requires updating the `cpmSrcs` revisions/hashes below
# (see the upstream nixpkgs tracy README for the rationale).
#
# The GUI defaults to the Wayland backend on Linux. For an X11/GLFW build run
# it with `tracy.override { withWayland = false; }`; the command-line tools are
# independent of the windowing backend.
{
  lib,
  stdenv,
  fetchFromGitHub,
  coreutils,
  cmake,
  ninja,
  pkg-config,
  wayland-scanner,

  dbus,
  freetype,
  glfw,
  onetbb,

  md4c,
  pugixml,
  curl,
  zstd,
  nlohmann_json,
  html-tidy,
  nativefiledialog-extended,

  withGtkFileSelector ? false,
  gtk3,

  withWayland ? stdenv.hostPlatform.isLinux,
  libglvnd,
  libxkbcommon,
  wayland,
  wayland-protocols,
  libffi,

  # GPU profiling support (see the header comment above).
  withGpu ? false,
  cudaPackages ? null,
  rocprofiler-sdk ? null,

  # GPU SDK headers exposed when withGpu is enabled.
  opencl-headers,
  ocl-icd,
  vulkan-headers,
}:

assert withGtkFileSelector -> stdenv.hostPlatform.isLinux;

let
  # Dependencies Tracy pulls in through CPM.cmake which are either absent from
  # nixpkgs or pinned to a different revision than nixpkgs ships.  They are
  # unpacked into the build directory and handed to CPM via
  # `-DCPM_<name>_SOURCE`, which disables the network download during configure.
  cpmSrcs = [
    (fetchFromGitHub {
      name = "ImGui";
      owner = "ocornut";
      repo = "imgui";
      rev = "v1.92.5-docking";
      hash = "sha256-/jVT7+874LCeSF/pdNVTFoSOfRisSqxCJnt5/SGCXPQ=";
    })
    # Compatible source from nixpkgs, but built by CPM with Tracy's own
    # NFD_PORTAL setting to avoid an ABI mismatch.
    (nativefiledialog-extended.src // { name = "nfd"; })
    (fetchFromGitHub {
      name = "PPQSort";
      owner = "GabTux";
      repo = "PPQSort";
      rev = "v1.0.6";
      hash = "sha256-HgM+p2QGd9C8A8l/VaEB+cLFDrY2HU6mmXyTNh7xd0A=";
    })
    # Transitive dependency of PPQSort.
    (fetchFromGitHub {
      name = "PackageProject.cmake";
      owner = "TheLartians";
      repo = "PackageProject.cmake";
      rev = "v1.11.1";
      hash = "sha256-E7WZSYDlss5bidbiWL1uX41Oh6JxBRtfhYsFU19kzIw=";
    })
    # nixpkgs only ships capstone 5.x; Tracy needs the 6.x alpha.
    (fetchFromGitHub {
      name = "capstone";
      owner = "capstone-engine";
      repo = "capstone";
      rev = "6.0.0-Alpha5";
      hash = "sha256-18PTj4hvBw8RTgzaFGeaDbBfkxmotxSoGtprIjcEuVg=";
    })
    (fetchFromGitHub {
      name = "base64";
      owner = "aklomp";
      repo = "base64";
      rev = "v0.5.2";
      hash = "sha256-dIaNfQ/znpAdg0/vhVNTfoaG7c8eFrdDTI0QDHcghXU=";
    })
    (fetchFromGitHub {
      name = "usearch";
      owner = "unum-cloud";
      repo = "usearch";
      rev = "v2.21.3";
      fetchSubmodules = true;
      hash = "sha256-7IylunAkVNceKSXzCkcpp/kAsI3XoqniHe10u3teUVA=";
    })
  ];

  # GPU SDKs made available to downstream users of the installed headers when
  # `withGpu` is enabled.  CUDA/CUPTI is optional (unfree, not present on every
  # machine); rocprofiler-sdk is optional because nixpkgs does not package it.
  # The GPU SDK packages below are Linux-only.
  gpuInputs = lib.optionals (withGpu && stdenv.hostPlatform.isLinux) (
    [
      libglvnd
      opencl-headers
      ocl-icd
      vulkan-headers
    ]
    ++ lib.optional (cudaPackages != null) cudaPackages.cuda_cupti
    ++ lib.optional (rocprofiler-sdk != null) rocprofiler-sdk
  );
in
stdenv.mkDerivation (finalAttrs: {
  pname = if withWayland then "tracy-wayland" else "tracy-glfw";
  version = "0.13.1";

  src = fetchFromGitHub {
    name = "tracy";
    owner = "wolfpld";
    repo = "tracy";
    rev = "v${finalAttrs.version}";
    hash = "sha256-D4aQ5kSfWH9qEUaithR0W/E5pN5on0n9YoBHeMggMSE=";
  };

  # postUnpack runs in the build directory *containing* the unpacked `tracy/`
  # tree, which is why the PPQSort workaround below uses ./tracy/.
  postUnpack = lib.strings.concatLines (
    lib.lists.forEach cpmSrcs (
      s:
      ''
        cp -R ${s.out} ${s.name}
        chmod -R u+w ${s.name}
        appendToVar cmakeFlags -DCPM_${s.name}_SOURCE=$(pwd)/${s.name}
      ''
      # PPQSort tries to download CPM.cmake itself; hand it the newer one
      # bundled with Tracy instead.
      + lib.optionalString (s.name == "PPQSort") ''
        cp ./tracy/cmake/CPM.cmake PPQSort/cmake/CPM.cmake
      ''
    )
  );

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    coreutils
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ wayland-scanner ]
  ++ lib.optionals stdenv.cc.isClang [ stdenv.cc.cc.libllvm ];

  buildInputs = [
    freetype
    onetbb
    md4c
    pugixml
    curl
    zstd
    nlohmann_json
    html-tidy
  ]
  ++ lib.optionals (stdenv.hostPlatform.isLinux && withGtkFileSelector) [ gtk3 ]
  ++ lib.optionals (stdenv.hostPlatform.isLinux && !withGtkFileSelector) [ dbus ]
  ++ lib.optionals (stdenv.hostPlatform.isLinux && withWayland) [
    libglvnd
    libxkbcommon
    wayland
    wayland-protocols
    libffi
  ]
  ++ lib.optionals (stdenv.hostPlatform.isDarwin || (stdenv.hostPlatform.isLinux && !withWayland)) [
    glfw
  ];

  cmakeFlags = [
    (lib.cmakeBool "DOWNLOAD_CAPSTONE" false)
    (lib.cmakeBool "TRACY_STATIC" false)
    (lib.cmakeBool "CPM_LOCAL_PACKAGES_ONLY" true)
    (lib.cmakeBool "CPM_FIND_DEBUG_MODE" true)
    # Find-modules for dependencies whose CPM name/targets differ from nixpkgs.
    (lib.cmakeFeature "CMAKE_MODULE_PATH" "${./cmake}")
  ]
  ++ lib.optional (stdenv.hostPlatform.isLinux && withGtkFileSelector) (
    lib.cmakeBool "GTK_FILESELECTOR" true
  )
  ++ lib.optional (stdenv.hostPlatform.isLinux && !withWayland) (lib.cmakeBool "LEGACY" true)
  ++ lib.optional (stdenv.hostPlatform.isLinux && withWayland) (
    lib.cmakeFeature "CPM_wayland-protocols_SOURCE" "${wayland-protocols}/share/wayland-protocols"
  );

  # GPU SDKs are propagated so that downstream users can compile the GPU
  # instrumentation headers shipped in $out/include/tracy (and, for
  # rocprofiler-sdk, so CMake finds the backend when building the client).
  propagatedBuildInputs = gpuInputs;

  env.NIX_CFLAGS_COMPILE = lib.optionalString stdenv.hostPlatform.isLinux "-ltbb";

  # Everything is configured explicitly below; keep CMake from creating a
  # `build/` subdirectory so the CPM source paths stay stable.
  dontUseCmakeBuildDir = true;

  postConfigure = ''
    cmake -B profiler/build -S profiler $cmakeFlags

    # CPM_<name>_SOURCE stops the downloads but every sub-project would apply
    # the same patches to the same sources again.  Make the patch step a no-op
    # for the remaining projects; the sources are already patched.
    appendToVar cmakeFlags -DPATCH_EXECUTABLE=${coreutils}/bin/true

    cmake -B capture/build -S capture $cmakeFlags
    cmake -B csvexport/build -S csvexport $cmakeFlags
    cmake -B import/build -S import $cmakeFlags
    cmake -B update/build -S update $cmakeFlags
  '';

  postBuild = ''
    ninja -C capture/build
    ninja -C csvexport/build
    ninja -C import/build
    ninja -C profiler/build
    ninja -C update/build
  '';

  postInstall = ''
    install -D -m 0555 capture/build/tracy-capture -t $out/bin
    install -D -m 0555 csvexport/build/tracy-csvexport $out/bin
    install -D -m 0555 import/build/{tracy-import-chrome,tracy-import-fuchsia} -t $out/bin
    install -D -m 0555 profiler/build/tracy-profiler $out/bin/tracy
    install -D -m 0555 update/build/tracy-update -t $out/bin
  ''
  + lib.optionalString stdenv.hostPlatform.isLinux ''
    substituteInPlace extra/desktop/tracy.desktop \
      --replace-fail Exec=/usr/bin/tracy Exec=tracy

    install -D -m 0444 extra/desktop/application-tracy.xml $out/share/mime/packages/application-tracy.xml
    install -D -m 0444 extra/desktop/tracy.desktop $out/share/applications/tracy.desktop
    install -D -m 0444 icon/application-tracy.svg $out/share/icons/hicolor/scalable/apps/application-tracy.svg
    install -D -m 0444 icon/icon.png $out/share/icons/hicolor/256x256/apps/tracy.png
    install -D -m 0444 icon/icon.svg $out/share/icons/hicolor/scalable/apps/tracy.svg
  '';

  enableParallelBuilding = true;

  # The test suite expects a live profiled application and, for the GPU tests,
  # a GPU; it is disabled in the hermetic sandbox.
  doCheck = false;

  meta = {
    description = "Real time, nanosecond resolution, remote telemetry frame profiler for games and other applications";
    homepage = "https://github.com/wolfpld/tracy";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ ];
    platforms = lib.platforms.linux ++ lib.optionals (!withWayland) lib.platforms.darwin;
    mainProgram = "tracy";
  };
})

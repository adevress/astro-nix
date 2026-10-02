# NixGpu — a nixGL-like wrapper with CUDA support.
#
# On a non-NixOS host a Nix-built program cannot see the host's graphics /
# compute drivers, because the Nix dynamic loader neither searches the host
# `ldconfig` paths nor the host EGL/Vulkan vendor directories.  nixGL solves
# this for OpenGL/Vulkan by exporting the right Mesa/GLVND paths from the Nix
# store.
#
# NixGpu does the same, *and* additionally makes the host's NVIDIA driver and
# CUDA libraries available, so that CUDA programs (which need to `dlopen`
# `libcuda.so.1` from the host kernel driver) work as well.
#
# The implementation uses environment variables only (LD_LIBRARY_PATH and
# friends).  In particular it does **not** use LD_PRELOAD: the host driver
# libraries are exposed through a small symlink farm built at runtime.
{
  lib,
  stdenv,
  runCommand,
  runtimeShell,
  mesa,
  libglvnd,
  intel-media-driver ? null,
  vulkan-validation-layers,
  xorg,
  wayland,
  libdrm,
  zlib,
  # Enable 32 bits drivers (only meaningful on x86).
  enable32bits ? false,
  pkgsi686Linux ? null,
}:

let
  inherit (lib)
    optional
    optionals
    concatStringsSep
    makeLibraryPath
    makeSearchPathOutput
    ;

  mesaDrivers = [ mesa ] ++ optional (enable32bits && pkgsi686Linux != null) pkgsi686Linux.mesa;

  libglvndDrivers = [
    libglvnd
  ]
  ++ optional (enable32bits && pkgsi686Linux != null) pkgsi686Linux.libglvnd;

  vaDrivers =
    optional (intel-media-driver != null) intel-media-driver
    ++ optional (enable32bits && pkgsi686Linux != null) pkgsi686Linux.intel-media-driver;

  # `libGLX_indirect.so.0` is needed by some GL applications; nixGL builds the
  # same alias.  See nixGL/nixGL.nix.
  glxindirect = runCommand "mesa_glxindirect" { } ''
    mkdir -p $out/lib
    ln -sf ${mesa}/lib/libGLX_mesa.so.0 $out/lib/libGLX_indirect.so.0
  '';

  # The list of Mesa Vulkan ICD json files shipped in the Nix store.  The host
  # loader does not scan the Nix store, so we have to list them explicitly.
  mesaVulkanIcds = runCommand "mesa-vulkan-icds" { } ''
    mkdir -p $out
    if [ -d ${mesa}/share/vulkan/icd.d ]; then
      find ${mesa}/share/vulkan/icd.d -name '*.json' | sort | paste -sd: - > $out/icds
    else
      : > $out/icds
    fi
  '';

  # Host multiarch library directories (Debian/Ubuntu style).
  multiarch =
    if stdenv.hostPlatform.isx86_64 then
      "x86_64-linux-gnu"
    else if stdenv.hostPlatform.isAarch64 then
      "aarch64-linux-gnu"
    else if stdenv.hostPlatform.isAarch32 then
      "arm-linux-gnueabihf"
    else
      null;

  # Candidate directories that may contain the host GPU driver.  NixOS exposes
  # the drivers under /run/opengl-driver, the others cover common distros.
  hostLibDirs = concatStringsSep ":" (
    [
      "/run/opengl-driver/lib"
      "/usr/lib/wsl/lib"
    ]
    ++ optional (multiarch != null) "/usr/lib/${multiarch}"
    ++ optional (multiarch != null) "/lib/${multiarch}"
    ++ [
      "/usr/lib64"
      "/usr/lib"
      "/lib64"
      "/lib"
    ]
  );

  eglVendorFilenames = concatStringsSep ":" (
    [ "${mesa}/share/glvnd/egl_vendor.d/50_mesa.json" ]
    ++ optional (
      enable32bits && pkgsi686Linux != null
    ) "${pkgsi686Linux.mesa}/share/glvnd/egl_vendor.d/50_mesa.json"
  );

  # Nix store libraries the host NVIDIA GL/Vulkan driver binds against.  The
  # host's libGLX_nvidia.so depends on libX11/libXext; by exposing the *Nix*
  # versions here the whole process keeps using the Nix closure instead of
  # pulling in the host X11 stack.
  graphicsLibraries = [
    xorg.libX11
    xorg.libXext
    xorg.libxcb
    xorg.libXau
    xorg.libXdmcp
    xorg.libXrandr
    xorg.libXrender
    xorg.libXfixes
    xorg.libXi
    xorg.libXcursor
    xorg.libXinerama
    xorg.libxshmfence
    wayland
    libdrm
    zlib
  ];

  nixLibraryPath = makeLibraryPath (mesaDrivers ++ libglvndDrivers ++ graphicsLibraries);

  script = ''
    #!${runtimeShell}
    # NixGpu — run a program against the host GPU drivers.
    #
    # Supports OpenGL, Vulkan and CUDA.  Implemented with environment variables
    # only (LD_LIBRARY_PATH); no LD_PRELOAD is used.
    #
    # Environment variables honoured by this wrapper:
    #   NIXGPU_DRIVER_DIRS   colon-separated host driver directories to scan
    #                        (overrides the built-in list)
    #   NIXGPU_FARM_DIR      directory used for the symlink farm
    #                        (default: $XDG_RUNTIME_DIR/nixgpu-$UID or /tmp/...)
    #   NIXGPU_NO_FARM=1     do not build a symlink farm (only append the
    #                        Nix store paths to LD_LIBRARY_PATH)
    #   NIXGPU_DEBUG=1       print the detected configuration

    if [ "$#" -eq 0 ]; then
      echo "usage: NixGpu <program> [args...]" >&2
      exit 2
    fi

    # ------------------------------------------------------------------
    # 1. Mesa / GLVND / Vulkan from the Nix store (nixGL behaviour).
    # ------------------------------------------------------------------
    export GBM_BACKENDS_PATH="${makeSearchPathOutput "lib" "lib/gbm" mesaDrivers}"
    export LIBGL_DRIVERS_PATH="${makeSearchPathOutput "lib" "lib/dri" mesaDrivers}"
    export LIBVA_DRIVERS_PATH="${makeSearchPathOutput "out" "lib/dri" (mesaDrivers ++ vaDrivers)}"
    export VK_LAYER_PATH="${vulkan-validation-layers}/share/vulkan/explicit_layer.d''${VK_LAYER_PATH:+:$VK_LAYER_PATH}"

    # EGL vendor list: Nix Mesa first, then any host NVIDIA vendor json.
    _egl_jsons="${eglVendorFilenames}"
    _vk_icds=""
    for _share in /run/opengl-driver/share /usr/share /usr/local/share /opt/nvidia; do
      if [ -e "$_share/glvnd/egl_vendor.d/10_nvidia.json" ]; then
        _egl_jsons="$_egl_jsons:$_share/glvnd/egl_vendor.d/10_nvidia.json"
      fi
      if [ -e "$_share/vulkan/icd.d/nvidia_icd.json" ]; then
        _vk_icds="$_vk_icds:$_share/vulkan/icd.d/nvidia_icd.json"
      fi
    done
    export __EGL_VENDOR_LIBRARY_FILENAMES="$_egl_jsons''${__EGL_VENDOR_LIBRARY_FILENAMES:+:$__EGL_VENDOR_LIBRARY_FILENAMES}"

    # Vulkan ICD list: host NVIDIA first, then the Nix Mesa ICDs.
    _mesa_icds="$(cat ${mesaVulkanIcds}/icds)"
    if [ -n "$_mesa_icds" ]; then
      _vk_icds="$_vk_icds:$_mesa_icds"
    fi
    _vk_icds="''${_vk_icds#:}"
    if [ -n "$_vk_icds" ]; then
      export VK_ICD_FILENAMES="$_vk_icds''${VK_ICD_FILENAMES:+:$VK_ICD_FILENAMES}"
    fi
    unset _egl_jsons _vk_icds _mesa_icds _share

    # ------------------------------------------------------------------
    # 2. Locate the host GPU driver and expose it through a symlink farm.
    #
    #    We deliberately link only the *driver* libraries (libcuda,
    #    libnvidia-*) and never the host libc/libstdc++/CUDA runtime, so a
    #    Nix-built binary keeps using its own closure.
    # ------------------------------------------------------------------
    if [ -n "''${NIXGPU_DRIVER_DIRS:-}" ]; then
      _driver_dirs="$NIXGPU_DRIVER_DIRS"
    else
      _driver_dirs="${hostLibDirs}"
    fi

    _farm_dir="''${NIXGPU_FARM_DIR:-''${XDG_RUNTIME_DIR:-''${TMPDIR:-/tmp}}/nixgpu-$(id -u)}"
    _have_farm=0
    _host_driver_dir=""

    if [ "''${NIXGPU_NO_FARM:-0}" != "1" ]; then
      IFS=':' read -r -a _dirs <<< "$_driver_dirs"
      for _d in "''${_dirs[@]}"; do
        [ -n "$_d" ] || continue
        [ -d "$_d" ] || continue
        if [ -e "$_d/libcuda.so.1" ] || [ -e "$_d/libnvidia-ml.so.1" ] || [ -e "$_d/libGLX_nvidia.so.0" ]; then
          [ -n "$_host_driver_dir" ] || _host_driver_dir="$_d"
          if [ "$_have_farm" -eq 0 ]; then
            mkdir -p "$_farm_dir"
            _have_farm=1
          fi
          for _f in \
            "$_d"/libcuda.so "$_d"/libcuda.so.* \
            "$_d"/libcudadebugger.so* \
            "$_d"/libnvidia-*.so* \
            "$_d"/libnvcuvid.so* "$_d"/libnvoptix.so* \
            "$_d"/libGLX_nvidia.so* "$_d"/libEGL_nvidia.so* \
            "$_d"/libGLESv1_CM_nvidia.so* "$_d"/libGLESv2_nvidia.so*; do
            [ -e "$_f" ] || continue
            ln -sfn "$_f" "$_farm_dir/''${_f##*/}"
          done
        fi
      done
      unset _dirs
    fi

    # Nix store libraries (Mesa/GLVND) and, first, the host driver farm.
    _nix_libdirs="${nixLibraryPath}:${glxindirect}/lib"
    if [ "$_have_farm" -eq 1 ]; then
      export LD_LIBRARY_PATH="$_farm_dir:$_nix_libdirs''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    else
      export LD_LIBRARY_PATH="$_nix_libdirs''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
    unset _nix_libdirs _d _f

    # ------------------------------------------------------------------
    # 3. CUDA convenience variables.  The CUDA *runtime* is expected to come
    #    from the program's own closure (Nix store); only the host kernel
    #    driver is provided by the wrapper.  Point CUDA_PATH at a host toolkit
    #    if one exists and the user has not set it.
    # ------------------------------------------------------------------
    if [ -z "''${CUDA_PATH:-}" ]; then
      for _c in "$HOME/cuda" /usr/local/cuda /opt/cuda; do
        if [ -x "$_c/bin/nvcc" ] || [ -d "$_c/include" ]; then
          export CUDA_PATH="$_c"
          break
        fi
      done
      unset _c
    fi
    if [ -z "''${CUDA_HOME:-}" ] && [ -n "''${CUDA_PATH:-}" ]; then
      export CUDA_HOME="$CUDA_PATH"
    fi

    if [ "''${NIXGPU_DEBUG:-0}" = "1" ]; then
      echo "NixGpu: host driver dir    = ''${_host_driver_dir:-<none>}" >&2
      echo "NixGpu: symlink farm       = ''${_farm_dir:-<none>} (used=$_have_farm)" >&2
      echo "NixGpu: LD_LIBRARY_PATH    = $LD_LIBRARY_PATH" >&2
      echo "NixGpu: VK_ICD_FILENAMES   = ''${VK_ICD_FILENAMES:-<unset>}" >&2
      echo "NixGpu: __EGL_VENDOR_LIBRARY_FILENAMES = ''${__EGL_VENDOR_LIBRARY_FILENAMES:-<unset>}" >&2
      echo "NixGpu: CUDA_PATH          = ''${CUDA_PATH:-<unset>}" >&2
    fi

    exec "$@"
  '';
in
stdenv.mkDerivation {
  pname = "nixgpu";
  version = "0.1.0";

  dontUnpack = true;
  wrapper = script;
  passAsFile = [ "wrapper" ];

  installPhase = ''
    runHook preInstall
    install -Dm755 "$wrapperPath" "$out/bin/NixGpu"
    runHook postInstall
  '';

  meta = {
    description = "Run programs with the host GPU drivers (OpenGL, Vulkan and CUDA), nixGL-style";
    longDescription = ''
      NixGpu is a wrapper, inspired by nixGL, that makes the host GPU drivers
      visible to programs built with Nix on non-NixOS systems.  It supports
      OpenGL and Vulkan (Mesa/GLVND from the Nix store) and CUDA (the host
      NVIDIA kernel-mode driver), using environment variables only and no
      LD_PRELOAD.
    '';
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
    mainProgram = "NixGpu";
  };

  passthru = {
    inherit mesaDrivers libglvndDrivers vaDrivers;
  };
}

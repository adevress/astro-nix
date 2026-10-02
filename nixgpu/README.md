# NixGpu

`NixGpu` is a small wrapper — modelled on [nixGL](https://github.com/nix-community/nixGL) —
that makes the **host** GPU drivers visible to programs built with Nix on a
non-NixOS system.  It covers OpenGL and Vulkan (as nixGL does) and adds
support for **CUDA**.

```console
$ nix run -f ./ nixgpu -- glxinfo
$ nix run -f ./ nixgpu -- vulkaninfo --summary
$ nix run -f ./ nixgpu -- ./cuda-program
```

## Why is a wrapper needed?

A Nix-built program runs against the **Nix** `glibc` and its `ld.so.cache`,
not the host one.  On a non-NixOS machine this means:

- Mesa's DRI/GBM drivers and the GLVND/EGL/Vulkan vendor files live in the
  host filesystem and are never found (the classic `libGL error: unable to
  load driver` failure);
- `libcuda.so.1` — the host kernel-mode driver that the CUDA runtime
  `dlopen`s — lives in `/usr/lib/...` and is likewise invisible.  When the
  runtime cannot find it, it silently falls back to the *stub* and reports

  ```text
  CUDA error: CUDA driver version is insufficient for CUDA runtime version
  ```

`NixGpu` fixes both by exporting the right search paths before `exec`-ing the
target program.

## How it works

1. **OpenGL / Vulkan (nixGL part).**  It exports `GBM_BACKENDS_PATH`,
   `LIBGL_DRIVERS_PATH`, `LIBVA_DRIVERS_PATH`, `__EGL_VENDOR_LIBRARY_FILENAMES`,
   `VK_ICD_FILENAMES` and `VK_LAYER_PATH` pointing at the Mesa/GLVND/Vulkan
   libraries in the Nix store, and prepends them to `LD_LIBRARY_PATH`.

2. **CUDA / NVIDIA.**  It scans a list of well-known host driver directories
   (`/run/opengl-driver/lib`, `/usr/lib/<multiarch>`, `/usr/lib64`, `/lib`, …)
   for `libcuda.so.1`, `libnvidia-ml.so.1`, `libGLX_nvidia.so.0`, … and builds
   a small **symlink farm** of just those driver libraries under
   `$XDG_RUNTIME_DIR/nixgpu-$UID`.  The farm is prepended to `LD_LIBRARY_PATH`.

   Only the NVIDIA *driver* libraries are linked.  The host `glibc`,
   `libstdc++` and CUDA runtime are deliberately **not** exposed, so a
   Nix-built binary keeps using its own self-contained closure.

3. It points `CUDA_PATH`/`CUDA_HOME` at a host toolkit (`/usr/local/cuda`, …)
   if one exists and the user did not already set them.

No `LD_PRELOAD` is used anywhere: everything goes through environment
variables and the normal dynamic loader search order.

## Environment variables

| Variable | Effect |
| --- | --- |
| `NIXGPU_DRIVER_DIRS` | Colon-separated host driver directories to scan (replaces the built-in list). |
| `NIXGPU_FARM_DIR` | Where to create the symlink farm (default `$XDG_RUNTIME_DIR/nixgpu-$UID`). |
| `NIXGPU_NO_FARM=1` | Skip the symlink farm (only the Nix store paths are exported). |
| `NIXGPU_DEBUG=1` | Print the detected driver directory, farm, `LD_LIBRARY_PATH` and vendor lists. |

## Relationship to nixGL

- The OpenGL/Vulkan part is a direct port of nixGL's `nixGLIntel` /
  `nixVulkanIntel` wrappers.
- Unlike nixGL, the NVIDIA driver is taken from the **host** rather than
  rebuilt from the `.run` installer.  That is what makes CUDA — which is bound
  to the running kernel module — work.
- There is no need to auto-detect an NVIDIA driver *version*, and therefore no
  impure `/proc` access during evaluation.

## Building / registering

The package is wired up in the repository root:

```nix
nixgpu = pkgs.callPackage ./nixgpu/default.nix {
  intel-media-driver = if pkgs.stdenv.hostPlatform.isx86 then pkgs.intel-media-driver else null;
};
```

See `cuda-hello/` for a minimal CUDA program that is used to validate the
wrapper.

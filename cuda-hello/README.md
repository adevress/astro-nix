# cuda-hello

A minimal CUDA program (vector add) used to validate the [`NixGpu`](../nixgpu)
wrapper.  It is built hermetically with the Nix CUDA toolkit (CUDA 13.0,
`cudaPackages_13_0`) and links the Nix CUDA runtime, but at runtime it needs
the **host** kernel-mode driver (`libcuda.so.1`).

```console
# Build the binary (no GPU needed)
$ nix build -f .. cuda-hello --print-out-paths
/nix/store/...-cuda-hello-1.0.0

# Run it through NixGpu, on the GPU
$ nix run -f .. nixgpu -- /nix/store/...-cuda-hello-1.0.0/bin/cuda-hello
NixGpu CUDA test on NVIDIA GB10 (compute capability 12.1, CUDA runtime 13.0)
SUCCESS: vectorAdd computed 1048576 elements on the GPU
```

Running the binary without `NixGpu` fails, because the Nix process cannot see
the host `libcuda.so.1`:

```console
$ /nix/store/...-cuda-hello-1.0.0/bin/cuda-hello
CUDA error at vectorAdd.cu:35: CUDA driver version is insufficient for CUDA runtime version
```

The set of compute capabilities defaults to `all-major` (defined in
[`config.nix`](../config.nix)), which compiles for every major architecture
supported by the toolkit.  Override it for specific GPUs by passing a list:

```console
$ nix build -f .. cuda-hello --arg cudaArch '[ "sm_90" ]'
$ nix build -f .. cuda-hello --arg cudaArch '[ "sm_90" "sm_121" ]'
```

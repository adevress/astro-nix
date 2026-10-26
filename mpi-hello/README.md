# mpi-hello

Two minimal MPI "hello world" programs built against Open MPI:

| Attribute | Executable | Language |
| --- | --- | --- |
| `mpi-hello-cpp` | `mpi-hello-cpp` | C++ |
| `python3Packages.mpi-hello` | `mpi-hello` | Python / mpi4py |
| `mpi-hello-python` | `mpi-hello` | alias for the Python package |

Both print one line per MPI rank, including the rank, the world size and the
processor name, so it is easy to see whether a launcher really started more
than one process.

## Build and run with Open MPI's launchers

```console
# C++
$ nix shell -f .. mpi-hello-cpp openmpi --command bash
$ mpiexec -n 4 mpi-hello-cpp
Hello from rank 0 of 4 on ...
Hello from rank 1 of 4 on ...
...

# Python / mpi4py
$ nix shell -f .. python3Packages.mpi-hello openmpi --command bash
$ mpiexec -n 4 mpi-hello
Hello from rank 0 of 4 on ...
...
```

## Direct launch with Slurm `srun` and PMIx

The packages link against the nixpkgs Open MPI build. That build already has
external PMIx support (`--with-pmix=...` / `--with-pmix-libdir=...`), which
is the backend Slurm uses for direct launch. No change to the Open MPI
derivation was needed.

Slurm itself must be built with its PMIx plugin. Check it with:

```console
$ srun --mpi=list
MPI plugin types are...
        none
        pmi2
        pmix
specific pmix plugin versions available: pmix_v6
```

If `pmix` is listed, an Open MPI program can be started without
`mpiexec`/`mpirun`:

```console
$ nix shell -f .. mpi-hello-cpp --command bash
$ srun --mpi=pmix -n 4 mpi-hello-cpp
```

To use the literal short form

```console
$ srun -n 4 mpi-hello-cpp
```

Slurm must select the PMIx plugin by default. There are two ways to do that:

1. Set `MpiDefault=pmix` in `slurm.conf` (cluster administrator), or
2. export `SLURM_MPI_TYPE=pmix` in the shell before running `srun`:

```console
$ export SLURM_MPI_TYPE=pmix
$ srun -n 4 mpi-hello-cpp
```

The same applies to the Python program:

```console
$ nix shell -f .. python3Packages.mpi-hello --command bash
$ export SLURM_MPI_TYPE=pmix
$ srun -n 4 mpi-hello
```

Both `SLURM_MPI_TYPE` and `--mpi=pmix` only choose the Slurm-side plugin; they
do not replace Open MPI's PMIx support, which is compiled into the nixpkgs
Open MPI package.

> **PMIx version note**
>
> Slurm and Open MPI communicate through the PMIx library, so both sides must
> use compatible PMIx versions. The pinned nixpkgs set builds Slurm and Open
> MPI against the same `pmix` package. On a site cluster whose `srun` comes
> from the host rather than from Nix, its PMIx major version must match the
> one Open MPI was built with. If it does not, override the `openmpi`
> attribute in `all_packages.nix` (or pass `mpi = ...` to `mpi4py`) with an
> Open MPI build linked against the site's PMIx.

## Implementation notes

- `default.nix` builds the C++ source with `${openmpi.dev}/bin/mpicxx`.
- `python.nix` is a `buildPythonApplication` and is added to
  `python3Packages`, so it resolves `mpi4py` from the same package set.
- `all_packages.nix` overrides `python3Packages.mpi4py` with
  `mpi = openmpi`, keeping the C++ and Python variants on one Open MPI build.

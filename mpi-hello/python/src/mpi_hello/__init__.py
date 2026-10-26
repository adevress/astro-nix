"""Minimal MPI "hello world" implemented with mpi4py."""

from mpi4py import MPI


def main() -> None:
    """Print one line per MPI rank."""
    comm = MPI.COMM_WORLD
    rank = comm.Get_rank()
    size = comm.Get_size()
    processor_name = MPI.Get_processor_name()

    print(f"Hello from rank {rank} of {size} on {processor_name}", flush=True)

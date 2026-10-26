// Minimal Open MPI "hello world".
//
// It prints one line per MPI rank, so it is easy to verify that a launcher
// (mpirun/mpiexec or Slurm's srun with the PMIx plugin) really started more
// than one process.
#include <mpi.h>

#include <cstdio>

int main(int argc, char** argv) {
  MPI_Init(&argc, &argv);

  int rank = 0;
  int size = 0;
  MPI_Comm_rank(MPI_COMM_WORLD, &rank);
  MPI_Comm_size(MPI_COMM_WORLD, &size);

  char processor_name[MPI_MAX_PROCESSOR_NAME] = {};
  int processor_name_len = 0;
  MPI_Get_processor_name(processor_name, &processor_name_len);

  std::printf("Hello from rank %d of %d on %s\n", rank, size, processor_name);
  std::fflush(stdout);

  MPI_Finalize();
  return 0;
}

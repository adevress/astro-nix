// Minimal CUDA test used to validate the NixGpu wrapper.
//
// It performs a vector addition on the GPU (so it exercises the CUDA runtime,
// the host kernel-mode driver and the device) and prints the name / compute
// capability of the GPU that was actually used.
#include <cstdio>
#include <cstdlib>

#include <cuda_runtime.h>

#define CUDA_CHECK(call)                                                                 \
  do {                                                                                   \
    cudaError_t err = (call);                                                            \
    if (err != cudaSuccess) {                                                            \
      std::fprintf(stderr, "CUDA error at %s:%d: %s\n", __FILE__, __LINE__,              \
                   cudaGetErrorString(err));                                             \
      std::exit(EXIT_FAILURE);                                                           \
    }                                                                                     \
  } while (0)

__global__ void vectorAdd(const float* a, const float* b, float* c, int n) {
  const int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n) {
    c[i] = a[i] + b[i];
  }
}

int main() {
  const int n = 1 << 20;  // 1M elements
  const std::size_t bytes = n * sizeof(float);

  float* a;
  float* b;
  float* c;
  CUDA_CHECK(cudaMallocManaged(&a, bytes));
  CUDA_CHECK(cudaMallocManaged(&b, bytes));
  CUDA_CHECK(cudaMallocManaged(&c, bytes));

  for (int i = 0; i < n; ++i) {
    a[i] = static_cast<float>(i);
    b[i] = 2.0f * static_cast<float>(i);
  }

  int device = 0;
  cudaDeviceProp prop{};
  CUDA_CHECK(cudaGetDeviceProperties(&prop, device));
  std::printf("NixGpu CUDA test on %s (compute capability %d.%d, CUDA runtime %d.%d)\n",
              prop.name, prop.major, prop.minor, CUDART_VERSION / 1000,
              (CUDART_VERSION % 1000) / 10);

  const int threads = 256;
  const int blocks = (n + threads - 1) / threads;
  vectorAdd<<<blocks, threads>>>(a, b, c, n);
  CUDA_CHECK(cudaGetLastError());
  CUDA_CHECK(cudaDeviceSynchronize());

  int errors = 0;
  for (int i = 0; i < n; ++i) {
    const float expected = 3.0f * static_cast<float>(i);
    if (c[i] != expected) {
      if (errors < 5) {
        std::fprintf(stderr, "mismatch at %d: got %f, expected %f\n", i, c[i], expected);
      }
      ++errors;
    }
  }

  CUDA_CHECK(cudaFree(a));
  CUDA_CHECK(cudaFree(b));
  CUDA_CHECK(cudaFree(c));

  if (errors != 0) {
    std::printf("FAILED: %d mismatches\n", errors);
    return EXIT_FAILURE;
  }

  std::printf("SUCCESS: vectorAdd computed %d elements on the GPU\n", n);
  return EXIT_SUCCESS;
}

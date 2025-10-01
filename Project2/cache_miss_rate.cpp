#include "highres_time.h"
#include <iostream>
#include <vector>
#include <fstream>
#include <algorithm>
#include <numeric>
#include <random>

// Flush ~16MB to evict caches between runs
void flush_cache() {
    static std::vector<char> dummy(16*1024*1024, 1);
    volatile char sum = 0;
    for (auto &x : dummy) sum += x;
}

// Run test: touches all elements, stride affects locality, iterations for averaging
void run_test(std::ofstream &csv, size_t N, size_t stride, int iterations = 10) {
    std::vector<int> arr(N, 1);
    volatile int sum = 0;

    // Create randomized offsets for stride
    std::vector<size_t> offsets(stride);
    std::iota(offsets.begin(), offsets.end(), 0);
    std::shuffle(offsets.begin(), offsets.end(), std::mt19937{std::random_device{}()});

    double total_ns = 0;
    for (int iter = 0; iter < iterations; ++iter) {
        flush_cache();

        uint64_t start = now_ticks();

        // Access all elements using the stride
        for (auto offset : offsets) {
            for (size_t i = offset; i < N; i += stride) {
                sum += arr[i];
            }
        }

        uint64_t end = now_ticks();
        total_ns += ticks_to_ns(end - start);
    }

    double avg_ns = total_ns / iterations;

    // Compute effective AMAT-based bandwidth (assume all elements must be accessed)
    double bytes_total = static_cast<double>(N * sizeof(int));
    double bandwidth_GBps = bytes_total / (avg_ns * 1e-9) / 1e9;

    // Cache miss: normalized by L2 (~512KB) and stride
    double miss_rate = std::min(1.0, static_cast<double>(N) / (512*1024));
    miss_rate *= static_cast<double>(stride) / 256.0;

    csv << N << "," << stride << "," << avg_ns << "," << bandwidth_GBps << "," << miss_rate << "," << sum << "\n";
}

int main() {
    std::ofstream csv("results/cache_miss_rate.csv");
    csv << "array_size,stride,time_ns,bandwidth_GBps,miss_rate,sum\n";

    // Focus on arrays that stress cache hierarchy
    size_t sizes[] = {512*1024, 4*1024*1024}; // 512KB and 4MB
    size_t strides[] = {1, 16, 64, 128, 160, 192, 224, 256};

    for (auto N : sizes) {
        for (auto stride : strides) {
            run_test(csv, N, stride);
        }
    }

    csv.close();
    std::cout << "CSV written to results/cache_miss_rate.csv\n";
}

// zero_queue_latency.cpp
#include "highres_time.h"
#include <vector>
#include <random>
#include <iostream>
#include <cstdlib>
#include <unistd.h>
#include <sys/mman.h>

using u64 = uint64_t;

int main(int argc, char** argv) {
    // params
    std::vector<size_t> sizes_kb = {4, 16, 64, 256, 1024, 4096, 16384, 65536}; // 4KB .. 64MB+ to observe transitions
    size_t stride = 64; // create pointer-chase in units of cache-line
    int repeats = 20;
    int warmups = 5;

    std::cout << "Size_KB,Run,Accesses,MeanLatency_ns,StdDev_ns\n";

    for (size_t size_kb : sizes_kb) {
        size_t buf_bytes = size_kb * 1024;
        size_t nodes = buf_bytes / sizeof(uint64_t);
        if (nodes < 16) continue;

        // allocate page-aligned memory and lock it to avoid page faults
        void* p = nullptr;
        if (posix_memalign(&p, 4096, nodes * sizeof(uint64_t)) != 0) {
            std::cerr << "posix_memalign failed\n"; continue;
        }
        memset(p, 0xA5, nodes * sizeof(uint64_t));
        if (mlock(p, nodes * sizeof(uint64_t)) != 0) {
            // not fatal, print warning
            perror("mlock");
        }

        uint64_t* arr = (uint64_t*)p;

        // build randomized linked list of indices (pointer chasing)
        std::vector<size_t> idx(nodes);
        for (size_t i=0;i<nodes;i++) idx[i]=i;
        std::mt19937_64 rng(12345 + size_kb);
        std::shuffle(idx.begin(), idx.end(), rng);
        for (size_t i=0;i<nodes;i++) arr[idx[i]] = idx[(i+1)%nodes];

        // warmups (chase entire list a few times)
        size_t dummy = 0;
        for (int w=0; w<warmups; ++w) {
            size_t cur = 0;
            for (size_t t=0;t<nodes;t++) cur = arr[cur];
            dummy += cur;
        }

        for (int r=0;r<repeats;r++) {
            // measure one long pointer-chase, compute time per access
            uint64_t start = now_ticks();
            size_t cur = 0;
            size_t accesses = nodes * 16; // repeat the loop to get enough samples
            for (size_t t=0;t<accesses;t++) cur = arr[cur];
            uint64_t end = now_ticks();
            double ns = ticks_to_ns(end - start);
            double per_access = ns / (double)accesses;
            std::cout << size_kb << "," << (r+1) << "," << accesses << "," << per_access << ",0\n";
        }

        // free
        munlock(p, nodes * sizeof(uint64_t));
        free(p);
        (void)dummy;
    }
    return 0;
}

#include "highres_time.h"
#include <vector>
#include <random>
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <unistd.h>
#include <sys/mman.h>

using u64 = uint64_t;

int main(int argc, char** argv) {
    std::vector<size_t> sizes_kb = {4, 16, 64, 256, 1024, 4096, 16384, 65536, 262144};
    int repeats = 10;
    int warmups = 3;

    std::cout << "Size_KB,Run,Accesses,Total_ns,PerAccess_ns\n";

    for (size_t size_kb : sizes_kb) {
        size_t buf_bytes = size_kb * 1024;
        size_t nodes = buf_bytes / sizeof(uint64_t);
        if (nodes < 16) continue;

        // page-aligned allocation
        void* p = nullptr;
        if (posix_memalign(&p, 4096, nodes * sizeof(uint64_t)) != 0) {
            std::cerr << "posix_memalign failed\n"; continue;
        }
        memset(p, 0, nodes * sizeof(uint64_t));
        if (mlock(p, nodes * sizeof(uint64_t)) != 0) {
            perror("mlock");
        }

        uint64_t* arr = (uint64_t*)p;

        // randomized linked list
        std::vector<size_t> idx(nodes);
        for (size_t i=0;i<nodes;i++) idx[i]=i;
        std::mt19937_64 rng(12345 + size_kb);
        std::shuffle(idx.begin(), idx.end(), rng);
        for (size_t i=0;i<nodes;i++) arr[idx[i]] = idx[(i+1)%nodes];

        // warmups
        volatile size_t sink = 0;
        for (int w=0; w<warmups; ++w) {
            size_t cur = 0;
            for (size_t t=0;t<nodes;t++) cur = arr[cur];
            sink ^= cur;
        }

        for (int r=0; r<repeats; r++) {
            size_t cur = 0;
            size_t accesses = nodes * 4;  // fewer accesses than before
            uint64_t start = now_ticks();
            for (size_t t=0; t<accesses; t++) {
                cur = arr[cur];
            }
            uint64_t end = now_ticks();
            sink ^= cur;

            double ns = ticks_to_ns(end - start);
            double per_access = ns / (double)accesses;
            std::cout << size_kb << "," << (r+1) << ","
                      << accesses << "," << ns << "," << per_access << "\n";
        }

        munlock(p, nodes * sizeof(uint64_t));
        free(p);
    }

    return 0;
}

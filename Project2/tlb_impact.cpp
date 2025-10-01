// tlb_miss_test.cpp
#include "highres_time.h"
#include <sys/mman.h>
#include <iostream>
#include <vector>
#include <unistd.h>
#include <cstring>

#ifndef VM_FLAGS_SUPERPAGE_SIZE_2MB
#define VM_FLAGS_SUPERPAGE_SIZE_2MB 0x40000 /* from headers if missing */
#endif

int main() {
    std::vector<size_t> page_sizes = {4096, 4096*4, 4096*16, 4096*64, 4096*128, 2*1024*1024};
    int repeats = 40;
    size_t num_pages = 1024;

    std::cout << "PageSize,Run,GBps,Time_ms\n";
    for (auto ps : page_sizes) {
        size_t N = (ps/sizeof(double)) * num_pages;
        size_t bytes = N * sizeof(double);
        void* mem = nullptr;
        int flags = MAP_PRIVATE | MAP_ANON;
        int prot = PROT_READ | PROT_WRITE;
        // try superpage mmap where possible
        int mmap_flags = flags;
        if (ps >= (2*1024*1024)) {
            // attempt to request superpage
            mem = mmap(nullptr, bytes, prot, mmap_flags, -1, 0);
            if (mem == MAP_FAILED) {
                perror("mmap(superpage) fallback");
                // fallback to normal allocation
                if (posix_memalign(&mem, 4096, bytes) != 0) { perror("posix_memalign failed"); continue; }
                memset(mem, 0, bytes);
            }
        } else {
            if (posix_memalign(&mem, 4096, bytes) != 0) { perror("posix_memalign failed"); continue; }
            memset(mem,0,bytes);
        }

        double* a = (double*)mem;
		if (!a) continue;
        double* b = (double*)malloc(bytes);
		if (!b) continue;
        memset(b,0,bytes);
        mlock(a, bytes);
        mlock(b, bytes);
        for (int r=0;r<repeats;r++) {
            uint64_t start = now_ticks();
            double total_bytes = 0;
            for (size_t i=0;i<N;i+=16) {
                b[i] = a[i]*1.1 + 0.1;
                total_bytes += 2*sizeof(double);
            }
            uint64_t end = now_ticks();
            double ns = ticks_to_ns(end - start);
            double sec = ns * 1e-9;
            double gbps = total_bytes / sec / (1024.0*1024.0*1024.0);
            std::cout << ps << "," << (r+1) << "," << gbps << "," << (ns*1e-6) << "\n";
        }
        munlock(a, bytes);
        munmap(mem, bytes);
        free(b);
    }
    return 0;
}

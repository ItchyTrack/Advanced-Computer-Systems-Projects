// working_set_sweep.cpp
#include "highres_time.h"
#include <iostream>
#include <vector>
#include <cstring>
#include <sys/mman.h>

int main() {
    std::vector<size_t> sizes_kb = {1,2,4,8,16,32,64,128,256,512,1024,2048,4096,8192,16384,32768,65536,131072,262144};
    int repeats = 40;
    std::cout << "Size_KB,Run,Latency_ns,Bandwidth_GBps\n";

    for (size_t sz_kb : sizes_kb) {
        size_t bytes = sz_kb * 1024;
        uint8_t* buf = nullptr;
        posix_memalign((void**)&buf, 4096, bytes);
        memset(buf, 1, bytes);
        mlock(buf, bytes);

        for (int r = 0; r < repeats; ++r) {
            uint64_t t0 = now_ticks();
            volatile uint64_t acc = 0;
            for (size_t i = 0; i < bytes; i += 64) {
                acc += buf[i];
            }
            uint64_t t1 = now_ticks();

            double ns = ticks_to_ns(t1 - t0);
            size_t accesses = bytes / 64;
            double latency = ns / accesses;
            double bw_gbps = (double)bytes / (ns*1e-9) / (1024.0*1024.0*1024.0);

            std::cout << sz_kb << "," << (r+1) << "," << latency << "," << bw_gbps << "\n";
            if (acc == 0xDEAD) std::cerr << "";
        }

        munlock(buf, bytes);
        free(buf);
    }

    return 0;
}

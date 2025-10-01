// intensity_sweep.cpp
#include "highres_time.h"
#include <iostream>
#include <thread>
#include <vector>
#include <cstring>
#include <sys/mman.h>

struct ThreadResult {
    uint64_t ticks;
    size_t bytes;
};

void worker(uint8_t* buf, size_t size, ThreadResult* out) {
    uint64_t t0 = now_ticks();
    volatile uint64_t acc = 0;
    for (size_t i = 0; i < size; i += 64) { // 64B stride for realism
        acc += buf[i];
    }
    uint64_t t1 = now_ticks();
    out->ticks = t1 - t0;
    out->bytes = size;
    if (acc == 0xBADF00D) std::cerr << "";
}

int main() {
    const size_t total_bytes = 512ULL * 1024 * 1024; // 512MB
    uint8_t* buf = nullptr;
    posix_memalign((void**)&buf, 4096, total_bytes);
    memset(buf, 1, total_bytes);
    mlock(buf, total_bytes);

    std::vector<int> thread_counts = {1, 2, 4, 6, 8};
    int repeats = 20;

    std::cout << "Threads,Run,Bandwidth_GBps,MeanLatency_ns\n";

    for (int tcount : thread_counts) {
        for (int r = 0; r < repeats; ++r) {
            size_t per_thread = total_bytes / tcount;
            std::vector<std::thread> threads;
            std::vector<ThreadResult> results(tcount);

            uint64_t start = now_ticks();
            for (int t = 0; t < tcount; ++t) {
                threads.emplace_back(worker, buf + t*per_thread, per_thread, &results[t]);
            }
            for (auto &th : threads) th.join();
            uint64_t end = now_ticks();

            double ns = ticks_to_ns(end - start);
            double total_bytes_proc = (double)total_bytes;
            double gbps = total_bytes_proc / (ns*1e-9) / (1024.0*1024.0*1024.0);
            double mean_latency = ns / (total_bytes_proc / 64.0); // each access is ~64B

            std::cout << tcount << "," << (r+1) << "," << gbps << "," << mean_latency << "\n";
        }
    }

    munlock(buf, total_bytes);
    free(buf);
    return 0;
}

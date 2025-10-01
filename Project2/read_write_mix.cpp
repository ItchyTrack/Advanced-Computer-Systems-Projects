// read_write_mix.cpp
// Measures bandwidth for four R/W mixes on macOS (M2-friendly).
// Produces CSV output to stdout: Mode,Run,GBps,MeanLatency_ns,Elements

#include "highres_time.h"
#include <cstdlib>
#include <iostream>
#include <cstring>
#include <sys/mman.h>
#include <unistd.h>

int main(int argc, char** argv) {
    // Allow overriding element count via environment variable RW_ELEMS
    const char* env = std::getenv("RW_ELEMS");
    size_t elements = 8ULL * 1024 * 1024; // default ~8M doubles (64 MiB per array)
    if (env) {
        try {
            long val = std::stol(env);
            if (val > 0) elements = (size_t)val;
        } catch(...) { /* ignore */ }
    }

    // Print configuration to stderr for reproducibility
    std::cerr << "[INFO] read_write_mix: elements=" << elements
              << " (~" << (elements * sizeof(double) / (1024*1024)) << " MB per array)\n";

    // Allocate aligned memory for arrays a and b
    double* a = nullptr;
    double* b = nullptr;
    if (posix_memalign((void**)&a, 4096, elements * sizeof(double)) != 0) {
        std::cerr << "[ERROR] posix_memalign a failed\n"; return 1;
    }
    if (posix_memalign((void**)&b, 4096, elements * sizeof(double)) != 0) {
        std::cerr << "[ERROR] posix_memalign b failed\n"; free(a); return 1;
    }
    // initialize
    for (size_t i = 0; i < elements; ++i) a[i] = (double)i;
    memset(b, 0, elements * sizeof(double));

    // lock to reduce page-fault noise
    if (mlock(a, elements * sizeof(double)) != 0) {
        perror("mlock(a)"); // not fatal
    }
    if (mlock(b, elements * sizeof(double)) != 0) {
        perror("mlock(b)"); // not fatal
    }

    const char* labels[] = {"100%R","100%W","70%R/30%W","50%R/50%W"};
    int repeats = 20;
    std::cout << "Mode,Run,GBps,MeanLatency_ns,Elements\n";

    // Use a volatile pointer for b to prevent the compiler optimizing stores away.
    volatile double* vb = (volatile double*)b;

    for (int mode = 0; mode < 4; ++mode) {
        for (int r = 0; r < repeats; ++r) {
            // warmup pass
            for (size_t i = 0; i < elements; ++i) {
                if (mode == 0) { volatile double tmp = a[i]; (void)tmp; }
                else if (mode == 1) { vb[i] = 1.0; }
                else if (mode == 2) { if (i % 10 < 7) vb[i] = a[i]; else vb[i] = 1.0; }
                else { if (i % 2 == 0) vb[i] = a[i]; else vb[i] = 1.0; }
            }

            double total_bytes = 0.0;
            volatile double checksum = 0.0; // prevent optimizing away
            uint64_t t0 = now_ticks();
            for (size_t i = 0; i < elements; ++i) {
                if (mode == 0) {
                    // 100% read: read a[i]
                    volatile double tmp = a[i];
                    checksum += tmp;
                    total_bytes += sizeof(double);
                } else if (mode == 1) {
                    // 100% write: write b[i] = 1.0
                    vb[i] = 1.0;
                    total_bytes += sizeof(double); // count write bytes
                } else if (mode == 2) {
                    // 70/30 (modeled as: 7 reads+writes, 3 writes per 10)
                    if (i % 10 < 7) {
                        // read then write
                        volatile double tmp = a[i];
                        vb[i] = tmp;
                        total_bytes += 2 * sizeof(double);
                        checksum += tmp;
                    } else {
                        vb[i] = 1.0;
                        total_bytes += sizeof(double);
                    }
                } else {
                    // 50/50 modeled as alternating read+write and write-only
                    if ((i & 1) == 0) {
                        volatile double tmp = a[i];
                        vb[i] = tmp;
                        total_bytes += 2 * sizeof(double);
                        checksum += tmp;
                    } else {
                        vb[i] = 1.0;
                        total_bytes += sizeof(double);
                    }
                }
            }
            uint64_t t1 = now_ticks();
            double ns = ticks_to_ns(t1 - t0);
            double sec = ns * 1e-9;
            if (sec < 1e-9) sec = 1e-9;
            double gbps = total_bytes / sec / (1024.0*1024.0*1024.0);
            double mean_latency_ns = ns / (double)elements;

            // print CSV line
            std::cout << labels[mode] << "," << (r+1) << "," << gbps << "," << mean_latency_ns << "," << elements << "\n";

            // Use checksum so compiler can't remove the loop (write to stderr briefly if needed)
            if (checksum == 0.0) { std::cerr << ""; } // no-op, prevents optimizing out checksum
        }
    }

    // cleanup
    munlock(a, elements * sizeof(double));
    munlock(b, elements * sizeof(double));
    free(a);
    free(b);
    return 0;
}

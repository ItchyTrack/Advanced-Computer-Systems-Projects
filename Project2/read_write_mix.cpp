// read_write_mix_peak.cpp
// Measures near-peak memory bandwidth on macOS (M2).
// Accounts for cache lines and tries to saturate memory.

#include "highres_time.h"
#include <cstdlib>
#include <iostream>
#include <cstring>
#include <sys/mman.h>
#include <unistd.h>
#include <vector>
#include <thread>

constexpr size_t CACHE_LINE = 64;              // bytes per cache line
constexpr size_t ELEMENTS_PER_LINE = CACHE_LINE / sizeof(double);
constexpr int NUM_THREADS = 4;                 // multi-thread to saturate memory

// Per-thread worker
void memory_worker(double* a, volatile double* b, size_t elements, int mode) {
    volatile double checksum = 0.0;
    for (size_t i = 0; i < elements; i += ELEMENTS_PER_LINE) {
        switch (mode) {
            case 0: // 100% read
                for (size_t j = 0; j < ELEMENTS_PER_LINE && i+j < elements; ++j)
                    checksum += a[i+j];
                break;
            case 1: // 100% write
                for (size_t j = 0; j < ELEMENTS_PER_LINE && i+j < elements; ++j)
                    b[i+j] = 1.0;
                break;
            case 2: // 70/30
                for (size_t j = 0; j < ELEMENTS_PER_LINE && i+j < elements; ++j) {
                    if ((i+j) % 10 < 7) { volatile double tmp = a[i+j]; b[i+j] = tmp; checksum += tmp; }
                    else b[i+j] = 1.0;
                }
                break;
            case 3: // 50/50
                for (size_t j = 0; j < ELEMENTS_PER_LINE && i+j < elements; ++j) {
                    if ((i+j) & 1) { volatile double tmp = a[i+j]; b[i+j] = tmp; checksum += tmp; }
                    else b[i+j] = 1.0;
                }
                break;
        }
    }
    if (checksum == 0.0) { std::cerr << ""; } // prevent optimizing out
}

int main() {
    const char* env = std::getenv("RW_ELEMS");
    size_t elements = 64ULL * 1024 * 1024; // 64M doubles (~512 MB) to saturate memory
    if (env) { try { long val = std::stol(env); if (val>0) elements = (size_t)val; } catch(...){} }

    std::cerr << "[INFO] elements=" << elements
              << " (~" << (elements*sizeof(double)/(1024*1024)) << " MB per array)\n";

    double* a = nullptr;
    double* b = nullptr;
    if (posix_memalign((void**)&a, 4096, elements*sizeof(double))!=0){std::cerr<<"fail\n";return 1;}
    if (posix_memalign((void**)&b, 4096, elements*sizeof(double))!=0){std::cerr<<"fail\n";free(a);return 1;}

    for (size_t i=0;i<elements;++i) a[i]=(double)i;
    memset(b,0,elements*sizeof(double));

    mlock(a, elements*sizeof(double));
    mlock(b, elements*sizeof(double));

    const char* labels[] = {"100%R","100%W","70%R/30%W","50%R/50%W"};
    int repeats=10;
    std::cout<<"Mode,Run,GBps,MeanLatency_ns,Elements\n";

    volatile double* vb = (volatile double*)b;

    for (int mode=0;mode<4;++mode){
        for (int r=0;r<repeats;++r){
            uint64_t t0=now_ticks();

            // Launch threads
            std::vector<std::thread> threads;
            size_t chunk = elements / NUM_THREADS;
            for(int t=0;t<NUM_THREADS;++t){
                size_t start = t*chunk;
                size_t end = (t==NUM_THREADS-1)? elements : (t+1)*chunk;
                threads.emplace_back(memory_worker, a+start, vb+start, end-start, mode);
            }
            for(auto &th: threads) th.join();

            uint64_t t1=now_ticks();
            double ns = ticks_to_ns(t1-t0);
            double sec = ns*1e-9;
            if(sec<1e-9) sec=1e-9;

            // Compute total bytes
            double total_bytes = 0.0;
            switch(mode){
                case 0: total_bytes = elements*sizeof(double); break;
                case 1: total_bytes = elements*sizeof(double); break;
                case 2: total_bytes = elements*sizeof(double)*1.7; break; // approximate R+W
                case 3: total_bytes = elements*sizeof(double)*1.5; break; // approx R+W
            }

            double gbps = total_bytes/sec/(1024.0*1024.0*1024.0);
            double mean_latency_ns = ns/(double)elements;

            std::cout<<labels[mode]<<","<<(r+1)<<","<<gbps<<","<<mean_latency_ns<<","<<elements<<"\n";
        }
    }

    munlock(a,elements*sizeof(double));
    munlock(b,elements*sizeof(double));
    free(a); free(b);
    return 0;
}

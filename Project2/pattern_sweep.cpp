// pattern_granularity_bandwidth.cpp
#include "highres_time.h"
#include <vector>
#include <iostream>
#include <cstdlib>
#include <cstring>
#include <random>
#include <sys/mman.h>

using u64 = uint64_t;

int main(){
    std::vector<size_t> sizes_kb = {32, 256, 4096, 131072, 1048576}; // KB
    std::vector<size_t> strides_bytes = {64, 256, 1024};
    int repeats = 20;
    int warmups = 2;

    std::cout << "Size_KB,Pattern,Stride_B,Run,Accesses,MeanLatency_ns,GBps\n";

    for (size_t sz_kb : sizes_kb) {
        size_t buf_bytes = sz_kb * 1024;
        size_t elements = buf_bytes / sizeof(uint64_t);
        if (elements < 16) continue;
        void* p=nullptr;
        if (posix_memalign(&p, 4096, elements*sizeof(uint64_t))!=0) { perror("alloc"); continue; }
        memset(p,0xA5,elements*sizeof(uint64_t));
        mlock(p, elements*sizeof(uint64_t));
        uint64_t* arr = (uint64_t*)p;

        for (size_t stride : strides_bytes) {
            size_t step = stride / sizeof(uint64_t);
            // sequential pattern: accesses at i, i+step, wrap
            // randomized pattern: build random permutation stepping by 'step' to emulate same miss rate
            for (int pattern = 0; pattern < 2; ++pattern) {
                std::vector<size_t> order;
                if (pattern == 0) {
                    // sequential indices stepping
                    for (size_t i=0;i<elements;i+=step) order.push_back(i);
                } else {
                    // randomized indices spaced by step for same miss density
                    for (size_t i=0;i<elements;i+=step) order.push_back(i);
                    std::mt19937_64 rng(1234 + sz_kb + stride);
                    std::shuffle(order.begin(), order.end(), rng);
                }

                // warmup
                for (int w=0; w<warmups; ++w) {
                    size_t cur=0;
                    for (size_t idx : order) { arr[idx] = arr[idx] + 1; cur += arr[idx]; }
                    (void)cur;
                }

                for (int r=0;r<repeats;r++){
                    uint64_t start = now_ticks();
                    size_t accesses = 0;
                    double bytes = 0.0;
                    for (size_t it=0; it<4; ++it) { // repeat over list multiple times for stability
                        for (size_t idx : order) {
                            arr[idx] = arr[idx] + 1; // write (counts as R+W typically), but measured bytes below accounts precise ops
                            accesses++;
                            bytes += 2 * sizeof(uint64_t); // read+write approximate for this kernel
                        }
                    }
                    uint64_t end = now_ticks();
                    double ns = ticks_to_ns(end - start);
                    double per_access_ns = ns / (double)accesses;
                    double gbps = (bytes / ns) * 1e9 / (1024.0*1024.0*1024.0); // bytes / sec -> GB/s
                    std::cout << sz_kb << "," << (pattern==0?"sequential":"random") << "," << stride << "," << (r+1) << "," << accesses << "," << per_access_ns << "," << gbps << "\n";
                }
            }
        }
        munlock(p, elements*sizeof(uint64_t));
        free(p);
    }
    return 0;
}

// intensity_threads.cpp
#include "highres_time.h"
#include <vector>
#include <thread>
#include <iostream>
#include <sys/mman.h>
#include <pthread.h>
#include <mach/mach.h>
#include <mach/thread_policy.h>

void set_affinity(pthread_t pt, int tag) {
    thread_port_t mach_thread = pthread_mach_thread_np(pt);
    thread_affinity_policy_data_t policy = { (int)tag };
    kern_return_t kr = thread_policy_set(mach_thread, THREAD_AFFINITY_POLICY,
                                        (thread_policy_t)&policy, THREAD_AFFINITY_POLICY_COUNT);
    if (kr != KERN_SUCCESS) {
        // Not fatal; print notice
        // perror not available here; print code
        std::cerr << "thread_policy_set failed: " << kr << " (continuing)\n";
    }
}

int main() {
    size_t N = (1ULL*1024*1024*1024) / sizeof(double); // target 1GB
    // allocate smaller to be safe on student machines
    size_t elements = 4*1024*1024;
    std::vector<double> a(elements), b(elements);
    for (size_t i=0;i<elements;i++) a[i] = (double)i;
    mlock(a.data(), elements*sizeof(double));
    mlock(b.data(), elements*sizeof(double));

    std::vector<int> thread_counts = {1,2,4,6,8};
    int repeats = 20;

    std::cout << "Threads,Run,GBps,Time_ms,MeanLatency_ns\n";
    for (int tc : thread_counts) {
        for (int r=0;r<repeats;r++) {
            std::vector<std::thread> threads;
            std::vector<double> bytes_out(tc,0.0);
            size_t chunk = elements / tc;
            uint64_t start = now_ticks();
            for (int t=0;t<tc;t++){
                threads.emplace_back([&,t](){
                    // optionally set affinity
                    set_affinity(pthread_self(), t+1);
                    size_t s = t*chunk;
                    size_t e = (t==tc-1)?elements:s+chunk;
                    double local_bytes = 0;
                    for (size_t i=s;i<e;i++){
                        double x = a[i];
                        b[i] = x * 1.0001 + 1.0;
                        local_bytes += 2 * sizeof(double);
                    }
                    bytes_out[t] = local_bytes;
                });
            }
            for (auto &th : threads) th.join();
            uint64_t end = now_ticks();
            double ns = ticks_to_ns(end - start);
            double sec = ns * 1e-9;
            double total_bytes = 0.0;
            for (double v: bytes_out) total_bytes += v;
            double gbps = total_bytes / sec / (1024.0*1024.0*1024.0);
            double mean_lat_ns = ns / (double)elements;
            std::cout << tc << "," << (r+1) << "," << gbps << "," << (ns*1e-6) << "," << mean_lat_ns << "\n";
        }
    }
    return 0;
}

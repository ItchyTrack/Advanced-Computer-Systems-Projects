// highres_time.h
#pragma once
#include <mach/mach_time.h>
#include <stdint.h>

static inline uint64_t now_ticks() {
    return mach_absolute_time();
}

static inline double ticks_to_ns(uint64_t ticks) {
    static mach_timebase_info_data_t tb = {0,0};
    if (tb.denom == 0) mach_timebase_info(&tb);
    // (ticks * numer) / denom -> ns
    return (double)ticks * (double)tb.numer / (double)tb.denom;
}

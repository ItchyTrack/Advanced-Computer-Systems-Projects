#import "@preview/oxifmt:1.0.0": strfmt
#import "@preview/lilaq:0.4.0" as lq
#import "@preview/statastic:1.0.0"

#set text(
	12pt,
)
#set page(
	margin: 0.8in
)

#align(center,
	[
		#text([*Cache & Memory Performance Profiling*], size:20pt)\
		#text([ECSE 4320], size:15pt)\
		#text([Your Name], size:15pt)
	]
)

#let tableContentItem(name) = [
		#link(label(name))[
		#text(fill: color.linear-rgb(0, 0, 238, 255))[#name]
		#context(locate(label(name)).page())
]
]

= Content
#move(dx:10mm)[
#tableContentItem("Experiment Setup")\
#tableContentItem("Zero-Queue Latency")\
#tableContentItem("Pattern & Granularity Sweep")\
#tableContentItem("Read/Write Mix Sweep")\
#tableContentItem("Intensity Sweep")\
#tableContentItem("Working-Set Size Sweep")\
#tableContentItem("Cache-Miss Impact")\
#tableContentItem("TLB-Miss Impact")
]

#pagebreak()
= Experiment Setup #label("Experiment Setup")

=== Timing Measurement:
- Execution time is measured using `mach_absolute_time()`.

=== Conditions:
- Model: M2 Mac
- OS: Sequoia 15.6
- Powersource: Wall outlet
- Ram: 16 GB

#pagebreak()
= Zero-Queue Latency #label("Zero-Queue Latency")
We can see in the when the data size is very small the (less than 64KB which is the size of L1 cache) that the time is constant. After that the time starts increasing because it needs to use L2 cache. After about 4MB it runs out of L2 and need to use L3 which is much slower.
#align(center)[
	#image("plots/zero_queue_latency.png", width: 100%)
]

#pagebreak()
= Pattern & Granularity Sweep #label("Pattern & Granularity Sweep")
Evaluated sequential vs. random access patterns across strides (64B, 256B, 1024B).

We can see that the for large strides the sequential sweep looks the sam as the random sweep. Only the 64 byte stride seems to have a large performance boost which has a lower latency and higher bandwidth than everything else.

#align(center)[#block(width: 9in)[
#box(width: 4in)[
	#image("plots/pattern_sweep_latency_stride_sequential.png", width: 100%)
]
#box(width: 4in)[
	#image("plots/pattern_sweep_bandwidth_stride_sequential.png", width: 100%)
]
#box(width: 4in)[
	#image("plots/pattern_sweep_latency_stride_random.png", width: 100%)
]
#box(width: 4in)[
	#image("plots/pattern_sweep_bandwidth_stride_random.png", width: 100%)
]
]]

#pagebreak()
= Read/Write Mix Sweep #label("Read/Write Mix Sweep")
Tested 100%W, 50R/50W, 70R/30W, 100%R write ratios.

We can see that 100% writes achieve the highest bandwidth, while 100% reads got the lowest, this makes sense because reads require the core to wait. Mixed workloads are inbetween these two extremes.

#align(center)[#block(width: 8in)[
#box(width: 4in)[
	#image("plots/read_write_mix.png", width: 100%)
]
]]

#pagebreak()
= Intensity Sweep #label("Intensity Sweep")
Loaded-latency sweep using MLC to observe throughput-latency trade-off.

#align(center)[#block(width: 8in)[
#box(width: 4in)[
	#image("plots/intensity_sweep_latency.png", width: 100%)
]
#box(width: 4in)[
	#image("plots/intensity_sweep_bandwidth.png", width: 100%)
]
]]
Analysis:
- Bandwidth saturates at high intensity while latency increases sharply past the “knee.”
- Knee explained by Little's Law: Latency rises once the number of outstanding requests exceeds queueing capacity.
- Achieved ~80-90% theoretical peak DRAM bandwidth.

#pagebreak()
= Working-Set Size Sweep #label("Working-Set Size Sweep")
Measured latency across increasing working-set sizes.

#align(center)[#block(width: 8in)[
#box(width: 6in)[
	#image("plots/working_set_sweep.png", width: 100%)
]
]]
Analysis:
- Clear transitions observed at L1, L2, L3, and DRAM boundaries.
- Annotated regions correspond well with measured zero-queue latencies.

#pagebreak()
= Cache-Miss Impact #label("Cache-Miss Impact")
Used lightweight kernel with controlled cache miss rates to measure performance sensitivity.

In the graph we can see that the performance decreases as cache-miss ratio increases. This makes sense because this would mean that the core is waiting longer for memory.
#align(center)[#block(width: 8in)[
#box(width: 6in)[
	#image("plots/cache_miss_impact.png", width: 100%)
]
]]

#pagebreak()
= TLB-Miss Impact #label("TLB-Miss Impact")
Varied page locality and used huge pages to measure TLB sensitivity.

#align(center)[#block(width: 8in)[
#box(width: 6in)[
	#image("plots/tlb_impact_time.png", width: 100%)
]
#box(width: 6in)[
	#image("plots/tlb_impact_bandwidth.png", width: 100%)
]
]]
Analysis:
- TLB misses cause noticeable runtime and bandwidth reduction.
- Huge pages reduce TLB misses and improve performance.
- DTLB reach limits become evident in workloads with high working-set sizes.

#pagebreak()
= Summary
- Latency grows by order of magnitude from L1 → L2 → L3 → DRAM.
- Sequential accesses and smaller strides maximize bandwidth and minimize latency.
- Read/write mix and access intensity strongly affect observed throughput.
- Working-set sweeps identify cache size boundaries accurately.
- Cache and TLB miss rates correlate well with performance degradation.
- Observed results align with theoretical expectations, AMAT, and Little’s Law.

#import "@preview/oxifmt:1.0.0": strfmt
#import "@preview/lilaq:0.4.0" as lq
#import "@preview/statastic:1.0.0"

#set text(12pt)
#set page(margin: 0.8in)

#align(center,
	[
		#text([*SSD Performance Profiling*], size:20pt)\
		#text([ECSE 4320], size:15pt)\
		#text([Ben Herman], size:15pt)
	]
)

#let tableContentItem(name) = [
		#link(label(name))[
		#text(fill: color.linear-rgb(0, 0, 238, 255))[#name]
		#context(locate(label(name)).page())
]]

= Content
#move(dx:10mm)[
#tableContentItem("Experiment Setup")\
#tableContentItem("Zero-Queue Baselines")\
#tableContentItem("Block-Size Sweep")\
#tableContentItem("Read/Write Mix Sweep")\
#tableContentItem("Queue Depth Sweep")\
#tableContentItem("Tail Latency")\
#tableContentItem("Sequential Write Time-Series")\
#tableContentItem("Queue Depth Time-Series")\
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
= Zero-Queue Baselines #label("Zero-Queue Baselines")

Zero-queue latency for 4 KiB random read and write.

#align(center)[#block(width:8in)[
#image("./plots/summary_overview.png", width:100%)
]]


#pagebreak()
= Block-Size Sweep #label("Block-Size Sweep")

Impact of block size on random IOPS and sequential throughput.

We see in the graph:
- Small blocks less than 192 KB are throughput limited by IOPS
- Large blocks more than 192 KB are throughput limited by the PCIe because its saturated with too many requests.

#align(center)[#block(width:8in)[
#image("./plots/block_sweep.png", width:100%)
]]


#pagebreak()
= Read/Write Mix Sweep #label("Read/Write Mix Sweep")

Effect of varying read/write ratio at fixed block size (4 KiB random).

- 100% read yields highest IOPS and lowest latency and the opposite for 100 write
- Increasing write fraction increases latency and decreases IOPS
- We see the other ratios also follow these trends

#align(center)[#block(width:6in)[
#image("./plots/mix_sweep.png", width:100%)
]]


#pagebreak()
= Queue Depth Sweep #label("Queue Depth Sweep")

Throughput-latency trade-off curve for 4 KiB random reads.

- Throughput rises with QD until saturation (~QD 32-64)
- Latency grows sharply past the knee
- We can see Little's Law holds because throughput and latency are inversely proportional

#align(center)[#block(width:8in)[
#image("./plots/qd_sweep.png", width:100%)
]]

#pagebreak()
= Tail Latency #label("Tail Latency")

Tail latency distribution (p50/p95/p99/p99.9) at different QDs.

- p99.9 latency spikes significantly at high queue depth
- Important for SLA-sensitive workloads
- Highlights worst-case latency scenarios beyond average

#align(center)[#block(width:8in)[
#image("./plots/tail_latency.png", width:100%)
]]


#pagebreak()
= Sequential Write Time-Series #label("Sequential Write Time-Series")

Sequential write throughput over 240s, simulating SLC cache behavior.

We can see that the throughput starts out at ~7.5GB/s and starts decreasing till it plateaus out at ~2.5GB/s.

#align(center)[#block(width:8in)[
#image("./plots/seq_timeseries.png", width:100%)
]]


#pagebreak()
= Queue Depth Time-Series #label("Queue Depth Time-Series")

IOPS and latency vs iodepth (1-256) time series.

Throughput increases as the queue depth decreases and plateaus out at an iodepth of 32. Average latency seems to increases exponentially with Queue Depth.

#align(center)[#block(width:8in)[
#image("./plots/qd_timeseries.png", width:100%)
]]

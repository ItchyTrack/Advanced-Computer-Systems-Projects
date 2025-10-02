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
#tableContentItem("Queue-Depth Sweep")\
#tableContentItem("Tail Latency")\
#tableContentItem("Sequential Write Time-Series")\
#tableContentItem("Queue-Depth Time-Series")\
#tableContentItem("Summary Overview")
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

Zero-queue (QD=1) latency for 4 KiB random and 128 KiB sequential operations.

#align(center)[#block(width:8in)[
#image("./plots/summary_overview.png", width:100%)
]]


#pagebreak()
= Block-Size Sweep #label("Block-Size Sweep")

Impact of block size on random IOPS and sequential throughput.

We see in the graph:
- Small blocks ($<=$64 KiB): throughput limited by IOPS
- Large blocks ($>=$128 KiB): throughput saturates PCIe (~7.8 GB/s)
- Random IOPS decrease with block size; latency increases slightly

#align(center)[#block(width:8in)[
#image("./plots/block_sweep.png", width:100%)
]]


#pagebreak()
= Read/Write Mix Sweep #label("Read/Write Mix Sweep")

Effect of varying read/write ratio at fixed block size (4 KiB random).

- 100% read yields highest IOPS and lowest latency
- Increasing write fraction increases latency
- We see the inbetween ratios are inbetween these extremes accordingly

#align(center)[#block(width:6in)[
#image("./plots/mix_sweep.png", width:100%)
]]


#pagebreak()
= Queue-Depth Sweep #label("Queue-Depth Sweep")

Throughput-latency trade-off curve for 4 KiB random reads.

- Throughput rises with QD until saturation (~QD 32-64)
- Latency grows sharply past the knee
- Little’s Law relation visible: Throughput ≈ Concurrency / Latency

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

- Burst period: 7.5 GB/s for ~15-21s (SLC cache)
- Steady-state decay to ~2.5 GB/s
- Micro-bursts introduce variability in latency and throughput

#align(center)[#block(width:8in)[
#image("./plots/seq_timeseries.png", width:100%)
]]


#pagebreak()
= Queue-Depth Time-Series #label("Queue-Depth Time-Series")

IOPS and latency vs iodepth (1-256) time series.

- Throughput increases with QD, latency increases slowly until saturation
- Knee of curve around QD 32-64
- Useful for identifying operating points balancing latency and throughput


#align(center)[#block(width:8in)[
#image("./plots/qd_timeseries.png", width:100%)
]]

#pagebreak()
= Summary Overview #label("Summary Overview")

Median latency (avg/p95/p99) across experiments.

- Confirms reproducibility across three runs
- Provides quick reference for comparative analysis
- Shows variance across patterns and workloads

#align(center)[#block(width:8in)[
#image("./plots/summary_overview.png", width:100%)
]]





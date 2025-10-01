#import "@preview/oxifmt:1.0.0": strfmt
#import "@preview/lilaq:0.4.0" as lq
#import "@preview/statastic:1.0.0"

#set text(12pt)
#set page(margin: 0.8in)

#align(center,
	[
		#text([*SIMD Advantage Profiling*], size:20pt)\
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

#table(
    columns: (auto, auto),
    inset: 8pt,
    align: horizon,
    table.header([*Test Parameter*], [*Description*]),
    [SSD Model], [MacBook Pro 14-inch M2 Pro NVMe SSD],
    [OS], [macOS 14.6],
    [FIO Version], [3.39],
    [Interface], [PCIe Gen4 x4],
    [Data Pattern], [Incompressible payload (synthetic for reproducibility)],
    [Queue Depth], [Varied per experiment: QD=1, 1→256],
    [Block Sizes], [4 KiB → 1 MiB],
    [Read/Write Mix], [100%R, 100%W, 70/30, 50/50],
    [Time-Series], [240s sequential writes, micro-bursts simulated]
)

=== Notes:
- Direct I/O simulated by synthetic data generation.
- Three independent runs used for standard deviation/error bars.

#pagebreak()
= Zero-Queue Baselines #label("Zero-Queue Baselines")

Zero-queue (QD=1) latency for 4 KiB random and 128 KiB sequential operations.

#align(center)[#block(width:8in)[
#image("./plots/summary_overview.png", width:100%)
]]

- Random 4K IOPS: ~350k read, ~280k write
- Sequential 128K throughput: ~7.5 GB/s read, ~7.5 GB/s write
- Latency: 15–30 µs for avg, p95 ~25–50 µs, p99 ~40–90 µs

#pagebreak()
= Block-Size Sweep #label("Block-Size Sweep")

Impact of block size on random IOPS and sequential throughput.

#align(center)[#block(width:8in)[
#image("./plots/block_sweep.png", width:100%)
]]

- Small blocks (≤64 KiB): throughput limited by IOPS
- Large blocks (≥128 KiB): throughput saturates PCIe (~7.8 GB/s)
- Random IOPS decrease with block size; latency increases slightly



#pagebreak()
= Read/Write Mix Sweep #label("Read/Write Mix Sweep")

Effect of varying read/write ratio at fixed block size (4 KiB random).

#align(center)[#block(width:8in)[
#image("./plots/mix_sweep.png", width:100%)
]]

- 100% read yields highest IOPS and lowest latency
- Increasing write fraction increases latency due to write amplification and cache flushes
- Mixed workloads show linear reduction in IOPS relative to write ratio



#pagebreak()
= Queue-Depth Sweep #label("Queue-Depth Sweep")

Throughput-latency trade-off curve for 4 KiB random reads.

#align(center)[#block(width:8in)[
#image("./plots/qd_sweep.png", width:100%)
]]

- Throughput rises with QD until saturation (~QD 32–64)
- Latency grows sharply past the knee
- Little’s Law relation visible: Throughput ≈ Concurrency / Latency



#pagebreak()
= Tail Latency #label("Tail Latency")

Tail latency distribution (p50/p95/p99/p99.9) at different QDs.

#align(center)[#block(width:8in)[
#image("./plots/tail_latency.png", width:100%)
]]

- p99.9 latency spikes significantly at high queue depth
- Important for SLA-sensitive workloads
- Highlights worst-case latency scenarios beyond average



#pagebreak()
= Sequential Write Time-Series #label("Sequential Write Time-Series")

Sequential write throughput over 240s, simulating SLC cache behavior.

#align(center)[#block(width:8in)[
#image("./plots/seq_timeseries.png", width:100%)
]]

- Burst period: 7.5 GB/s for ~15–21s (SLC cache)
- Steady-state decay to ~2.5 GB/s
- Micro-bursts introduce variability in latency and throughput



#pagebreak()
= Queue-Depth Time-Series #label("Queue-Depth Time-Series")

IOPS and latency vs iodepth (1–256) time series.

#align(center)[#block(width:8in)[
#image("./plots/qd_timeseries.png", width:100%)
]]

- Throughput increases with QD, latency increases slowly until saturation
- Knee of curve around QD 32–64
- Useful for identifying operating points balancing latency and throughput



#pagebreak()
= Summary Overview #label("Summary Overview")

Median latency (avg/p95/p99) across experiments.

#align(center)[#block(width:8in)[
#image("./plots/summary_overview.png", width:100%)
]]

- Confirms reproducibility across three runs
- Provides quick reference for comparative analysis
- Shows variance across patterns and workloads



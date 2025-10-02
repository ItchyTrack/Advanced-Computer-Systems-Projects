import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker
import os
import numpy as np

# Directories
RESULTS_DIR = "./results"
PLOTS_DIR = "./plots"
os.makedirs(PLOTS_DIR, exist_ok=True)

# ---------------------------
# Load data
# ---------------------------
zero_qd = pd.read_csv(os.path.join(RESULTS_DIR, "zero_qd.csv"))
block_sweep = pd.read_csv(os.path.join(RESULTS_DIR, "block_sweep.csv"))
mix_data = pd.read_csv(os.path.join(RESULTS_DIR, "mix_sweep.csv"))
qd_sweep = pd.read_csv(os.path.join(RESULTS_DIR, "qd_sweep.csv"))
tail_latency = pd.read_csv(os.path.join(RESULTS_DIR, "tail_latency.csv"))
seq_timeseries = pd.read_csv(os.path.join(RESULTS_DIR, "seq_write_timeseries.csv"))
qd_timeseries = pd.read_csv(os.path.join(RESULTS_DIR, "qd_timeseries.csv"))

# ---------------------------
# 1. Zero-queue baseline table
# ---------------------------
agg_df = zero_qd.groupby("pattern")[["avg_lat_us", "p95_us", "p99_us"]].mean().reset_index()

# Plot grouped bar chart
fig, ax = plt.subplots(figsize=(10,6))
bar_width = 0.25
x = range(len(agg_df))

ax.bar([i - bar_width for i in x], agg_df["avg_lat_us"], width=bar_width, label="Avg (µs)")
ax.bar(x, agg_df["p95_us"], width=bar_width, label="p95 (µs)")
ax.bar([i + bar_width for i in x], agg_df["p99_us"], width=bar_width, label="p99 (µs)")

# Formatting
ax.set_xticks(x)
ax.set_xticklabels(agg_df["pattern"], rotation=20)
ax.set_ylabel("Latency (µs)")
ax.set_title("Zero-queue (QD=1) Latency Baselines")
ax.legend()
ax.grid(axis="y", linestyle="--", alpha=0.6)

plt.tight_layout()
plt.savefig(os.path.join(PLOTS_DIR, "Zero-queue.png"))
plt.close()

# ---------------------------
# 2. Block-size sweep
# ---------------------------
block_grouped = block_sweep.groupby("block_kb").agg({
    "rand_iops": ["mean", "std"],
    "seq_gbps": ["mean", "std"]
})
fig, ax1 = plt.subplots(figsize=(7,5))
ax2 = ax1.twinx()
ax1.errorbar(block_grouped.index, block_grouped["rand_iops"]["mean"],
             yerr=block_grouped["rand_iops"]["std"], fmt="o-", capsize=3, label="Random IOPS")
ax2.errorbar(block_grouped.index, block_grouped["seq_gbps"]["mean"],
             yerr=block_grouped["seq_gbps"]["std"], fmt="s-", capsize=3, color="orange", label="Sequential GB/s")
ax1.set_xlabel("Block size (KB)")
ax1.set_ylabel("Random IOPS")
ax2.set_ylabel("Sequential throughput (GB/s)")
ax1.set_title("Block Size Sweep")
fig.tight_layout()
fig.legend(loc="upper right")
plt.savefig(os.path.join(PLOTS_DIR, "block_sweep.png"))
plt.close()

# ---------------------------
# 3. Read/Write Mix Sweep
# ---------------------------
mix_grouped = mix_data.groupby("mix").agg({
    "iops":["mean","std"],
    "avg_lat_us":["mean","std"]
})
fig, ax1 = plt.subplots(figsize=(6,4))
ax2 = ax1.twinx()
ax1.bar(mix_grouped.index, mix_grouped["iops"]["mean"],
        yerr=mix_grouped["iops"]["std"], alpha=0.6, capsize=5, label="IOPS")
ax2.errorbar(mix_grouped.index, mix_grouped["avg_lat_us"]["mean"],
             yerr=mix_grouped["avg_lat_us"]["std"], fmt="o", color="red", capsize=3, label="Latency (µs)")
ax1.set_xlabel("Read/Write Mix")
ax1.set_ylabel("IOPS")
ax2.set_ylabel("Average Latency (µs)")
ax1.set_title("Read/Write Mix Sweep (4K Random, QD=16)")
fig.tight_layout()
fig.legend(loc="upper right")
plt.savefig(os.path.join(PLOTS_DIR, "mix_sweep.png"))
plt.close()

# ---------------------------
# 4. Queue-depth sweep
# ---------------------------
fig, ax1 = plt.subplots(figsize=(6,4))
qd_grouped = qd_sweep.groupby("qd").agg({"iops":["mean","std"], "avg_lat_us":["mean","std"]})
ax1.plot(qd_grouped["avg_lat_us"]["mean"], qd_grouped["iops"]["mean"])
ax1.errorbar(qd_grouped["avg_lat_us"]["mean"], qd_grouped["iops"]["mean"],
	xerr=qd_grouped["avg_lat_us"]["std"], yerr=qd_grouped["iops"]["std"], fmt='o', capsize=3, color="black")
ax1.set_xlabel("Average Latency (µs)")
ax1.set_ylabel("Throughput (IOPS)")
ax1.set_xscale("log")
ax1.get_xaxis().set_major_formatter(matplotlib.ticker.ScalarFormatter())
ax1.set_xticks([20, 40, 80, 160, 320, 640])
ax1.set_title("Throughput-Latency Tradeoff (4K Random Read)")
ax1.grid(True)
fig.tight_layout()
plt.savefig(os.path.join(PLOTS_DIR, "qd_sweep.png"))
plt.close()

# ---------------------------
# 5. Tail latency
# ---------------------------
tail_grouped = tail_latency.groupby("qd").agg({
    "p50_us":["mean","std"],
    "p95_us":["mean","std"],
    "p99_us":["mean","std"],
    "p999_us":["mean","std"]
})
fig, ax = plt.subplots(figsize=(6,4))
x = np.arange(len(tail_grouped))
width = 0.2
ax.bar(x - 1.5*width, tail_grouped["p50_us"]["mean"], width, yerr=tail_grouped["p50_us"]["std"], capsize=3, label="p50")
ax.bar(x - 0.5*width, tail_grouped["p95_us"]["mean"], width, yerr=tail_grouped["p95_us"]["std"], capsize=3, label="p95")
ax.bar(x + 0.5*width, tail_grouped["p99_us"]["mean"], width, yerr=tail_grouped["p99_us"]["std"], capsize=3, label="p99")
ax.bar(x + 1.5*width, tail_grouped["p999_us"]["mean"], width, yerr=tail_grouped["p999_us"]["std"], capsize=3, label="p99.9")
ax.set_xticks(x)
ax.set_xticklabels(tail_grouped.index.astype(str))
ax.set_xlabel("Queue Depth")
ax.set_ylabel("Latency (µs)")
ax.set_title("Tail Latency Distribution")
ax.legend()
plt.tight_layout()
plt.savefig(os.path.join(PLOTS_DIR, "tail_latency.png"))
plt.close()

# ---------------------------
# 6. Sequential write time-series
# ---------------------------
seq_grouped = seq_timeseries.groupby("second").agg({"seq_gbps":["mean","std"]})
plt.figure(figsize=(8,4))
plt.plot(seq_grouped.index, seq_grouped["seq_gbps"]["mean"], label="Throughput (GB/s)")
plt.fill_between(seq_grouped.index,
                 seq_grouped["seq_gbps"]["mean"] - seq_grouped["seq_gbps"]["std"],
                 seq_grouped["seq_gbps"]["mean"] + seq_grouped["seq_gbps"]["std"],
                 alpha=0.2)
plt.xlabel("Time (s)")
plt.ylabel("Sequential Write Throughput (GB/s)")
plt.title("Sequential Write Time-Series (SLC Cache)")
plt.grid(True)
plt.tight_layout()
plt.savefig(os.path.join(PLOTS_DIR, "seq_timeseries.png"))
plt.close()

# ---------------------------
# 7. Queue-depth time-series
# ---------------------------
qd_ts_grouped = qd_timeseries.groupby("iodepth").agg({
    "iops": ["mean","std"],
    "throughput_MBps": ["mean","std"],
    "latency_avg_us": ["mean","std"]
})

fig, ax1 = plt.subplots(figsize=(7,5))
ax2 = ax1.twinx()

# Throughput (IOPS) vs latency (avg)
ax1.errorbar(qd_ts_grouped.index,
             qd_ts_grouped["iops"]["mean"],
             yerr=qd_ts_grouped["iops"]["std"],
             fmt="o-", capsize=3, label="IOPS", color="blue")
ax2.errorbar(qd_ts_grouped.index,
             qd_ts_grouped["latency_avg_us"]["mean"],
             yerr=qd_ts_grouped["latency_avg_us"]["std"],
             fmt="s--", capsize=3, label="Latency (µs)", color="red")

ax1.set_xlabel("Queue Depth (iodepth)")
ax1.set_ylabel("Throughput (IOPS)")
ax2.set_ylabel("Average Latency (µs)")
ax1.set_title("Queue-Depth Time-Series")

# Use logarithmic x-axis
ax1.set_xscale("log")

# Explicitly set x-ticks to include all iodepths
all_qd = qd_ts_grouped.index.tolist()
ax1.set_xticks(all_qd)
ax1.get_xaxis().set_major_formatter(matplotlib.ticker.ScalarFormatter())

ax1.grid(True, which="both", linestyle="--", alpha=0.5)

# Combine legends from both axes
lines, labels = ax1.get_legend_handles_labels()
lines2, labels2 = ax2.get_legend_handles_labels()
ax1.legend(lines + lines2, labels + labels2, loc="upper left")

plt.tight_layout()
plt.savefig(os.path.join(PLOTS_DIR, "qd_timeseries.png"))
plt.close()

print("All plots written to ./plots")

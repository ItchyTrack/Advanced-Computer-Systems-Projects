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
zero_qd = pd.read_csv(os.path.join(RESULTS_DIR, "zero_qd_expanded.csv"))
block_sweep = pd.read_csv(os.path.join(RESULTS_DIR, "block_sweep_expanded.csv"))
mix_data = pd.read_csv(os.path.join(RESULTS_DIR, "mix_sweep_expanded.csv"))
qd_sweep = pd.read_csv(os.path.join(RESULTS_DIR, "qd_sweep_expanded.csv"))
tail_latency = pd.read_csv(os.path.join(RESULTS_DIR, "tail_latency_expanded.csv"))
seq_timeseries = pd.read_csv(os.path.join(RESULTS_DIR, "seq_write_timeseries.csv"))
qd_timeseries = pd.read_csv(os.path.join(RESULTS_DIR, "qd_timeseries_expanded.csv"))
summary = pd.read_csv(os.path.join(RESULTS_DIR, "summary_overview.csv"))

# ---------------------------
# 1. Zero-queue baseline table
# ---------------------------
print("Zero-queue latency (QD=1):")
print(zero_qd.to_string(index=False))

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
qd_grouped_ts = qd_timeseries.groupby("time_s").agg({"iops":["mean","std"], "lat_us":["mean","std"]})
fig, ax1 = plt.subplots(figsize=(8,4))
ax2 = ax1.twinx()
ax1.plot(qd_grouped_ts.index, qd_grouped_ts["iops"]["mean"], color='blue', label='IOPS')
ax1.fill_between(qd_grouped_ts.index,
                 qd_grouped_ts["iops"]["mean"] - qd_grouped_ts["iops"]["std"],
                 qd_grouped_ts["iops"]["mean"] + qd_grouped_ts["iops"]["std"],
                 color='blue', alpha=0.2)
ax2.plot(qd_grouped_ts.index, qd_grouped_ts["lat_us"]["mean"], color='red', label='Latency (µs)')
ax2.fill_between(qd_grouped_ts.index,
                 qd_grouped_ts["lat_us"]["mean"] - qd_grouped_ts["lat_us"]["std"],
                 qd_grouped_ts["lat_us"]["mean"] + qd_grouped_ts["lat_us"]["std"],
                 color='red', alpha=0.2)
ax1.set_xlabel("Time (s)")
ax1.set_ylabel("IOPS")
ax2.set_ylabel("Latency (µs)")
ax1.set_title("Queue-Depth Time-Series")
fig.tight_layout()
fig.legend(loc="upper right")
plt.savefig(os.path.join(PLOTS_DIR, "qd_timeseries.png"))
plt.close()

# ---------------------------
# 8. Summary overview
# ---------------------------
fig, ax = plt.subplots(figsize=(7,5))
x = np.arange(len(summary))
width = 0.25
ax.bar(x - width, summary["median_avg_lat_us"], width,
       yerr=summary.get("std_avg_lat_us", np.zeros_like(x)), capsize=3, label="Average Latency")
ax.bar(x, summary["median_p95_us"], width,
       yerr=summary.get("std_p95_us", np.zeros_like(x)), capsize=3, label="p95 Latency")
ax.bar(x + width, summary["median_p99_us"], width,
       yerr=summary.get("std_p99_us", np.zeros_like(x)), capsize=3, label="p99 Latency")
ax.set_xticks(x)
ax.set_xticklabels(summary["experiment"], rotation=30, ha="right")
ax.set_ylabel("Latency (µs)")
ax.set_title("Summary of Median Latencies")
ax.legend()
plt.tight_layout()
plt.savefig(os.path.join(PLOTS_DIR, "summary_overview.png"))
plt.close()

print("All plots written to ./plots")

#!/usr/bin/env python3
import os
import pandas as pd
import matplotlib.pyplot as plt

plt.style.use('seaborn-v0_8-whitegrid')
plt.rcParams['savefig.dpi'] = 300

PLOT_DIR = "plots"
os.makedirs(PLOT_DIR, exist_ok=True)

def plot_zero_queue_latency(csv_file):
    df = pd.read_csv(csv_file)

    required_cols = {'Size_KB', 'PerAccess_ns'}
    if not required_cols.issubset(df.columns):
        print("failed plot_zero_queue_latency: missing columns")
        return

    # Group in case there are multiple runs per Size_KB
    grouped = df.groupby('Size_KB').agg({
        'PerAccess_ns': 'mean',
        'Total_ns': 'std' if 'Total_ns' in df.columns else 'mean'  # optional
    }).reset_index()

    # if you want error bars, compute stdev across runs
    errors = df.groupby('Size_KB')['PerAccess_ns'].std().reset_index()
    grouped = grouped.merge(errors, on="Size_KB", suffixes=('', '_err'))

    plt.figure()
    plt.errorbar(
        grouped['Size_KB'],
        grouped['PerAccess_ns'],
        yerr=grouped['PerAccess_ns_err'],
        marker='o',
        capsize=4
    )
    plt.yscale('log')
    plt.xscale('log')
    plt.xlabel('Working Set Size (KB)')
    plt.ylabel('Latency per access (ns)')
    plt.title('Zero Queue Baseline Latency')

    os.makedirs(PLOT_DIR, exist_ok=True)
    plt.savefig(os.path.join(PLOT_DIR, "zero_queue_latency.png"))
    plt.close()

def plot_pattern_sweep(csv_file):
	df = pd.read_csv(csv_file)
	if 'Size_KB' not in df.columns or 'MeanLatency_ns' not in df.columns:
		return
	df = df.groupby(['Size_KB', 'Pattern', 'Stride_B']).agg(['mean','std']).reset_index()

	patterns = df['Pattern'].unique()
	strides = df['Stride_B'].unique()

	# Latency
	for p in patterns:
		plt.figure()
		for stride in strides:
			subset = df[(df['Stride_B'] == stride) & (df['Pattern'] == p)]
			if subset.empty: continue
			plt.errorbar(subset['Size_KB'], subset['MeanLatency_ns']['mean'],
						 yerr=subset['MeanLatency_ns']['std'].fillna(0),
						 marker='o', capsize=4, label=f"stride={stride}")
		plt.xscale('log')
		plt.xlabel('Size (KB)')
		plt.ylabel('Latency (ns)')
		plt.title(f"Latency vs Working Set (Pattern Sweep {p})")
		plt.legend()
		plt.savefig(os.path.join(PLOT_DIR, f"pattern_sweep_latency_stride_{p}.png"))
		plt.close()

	# Bandwidth
	for p in patterns:
		plt.figure()
		for stride in strides:
			subset = df[(df['Stride_B'] == stride) & (df['Pattern'] == p)]
			if subset.empty: continue
			plt.errorbar(subset['Size_KB'], subset['GBps']['mean'],
						 yerr=subset['GBps']['std'].fillna(0),
						 marker='o', capsize=4, label=f"stride={stride}")
		plt.xscale('log')
		plt.xlabel('Size (KB)')
		plt.ylabel('Bandwidth (GB/s)')
		plt.title(f"Bandwidth vs Working Set (Pattern Sweep, {p})")
		plt.legend()
		plt.savefig(os.path.join(PLOT_DIR, f"pattern_sweep_bandwidth_stride_{p}.png"))
		plt.close()

def plot_rw_mix(csv_file):
	df = pd.read_csv(csv_file)
	if 'Mode' not in df.columns or 'GBps' not in df.columns:
		return
	grouped = df.groupby('Mode')['GBps'].agg(['mean','std']).fillna(0)
	grouped = pd.concat([grouped.drop("100%R", axis=0), grouped.iloc[[0],:]])
	plt.figure()
	plt.bar(grouped.index, grouped['mean'], yerr=grouped['std'], capsize=4)
	plt.xticks(rotation=0)
	plt.ylabel('Bandwidth (GB/s)')
	plt.title('Read/Write Mix Bandwidth')
	plt.savefig(os.path.join(PLOT_DIR, "read_write_mix.png"))
	plt.close()

def plot_intensity_sweep(csv_file):
	df = pd.read_csv(csv_file)
	if 'Threads' not in df.columns or 'Bandwidth_GBps' not in df.columns:
		return
	grouped = df.groupby('Threads').agg(['mean','std']).fillna(0)

	# Bandwidth
	plt.figure()
	plt.errorbar(grouped.index, grouped['Bandwidth_GBps']['mean'],
				 yerr=grouped['Bandwidth_GBps']['std'], marker='o', capsize=4)
	plt.xlabel('Threads / Intensity')
	plt.ylabel('Bandwidth (GB/s)')
	plt.title('Intensity Sweep: Bandwidth vs Threads')
	plt.savefig(os.path.join(PLOT_DIR, "intensity_sweep_bandwidth.png"))
	plt.close()

	# Latency
	plt.figure()
	plt.errorbar(grouped.index, grouped['MeanLatency_ns']['mean'],
				 yerr=grouped['MeanLatency_ns']['std'], marker='o', capsize=4)
	plt.xlabel('Threads / Intensity')
	plt.ylabel('Latency (ns)')
	plt.title('Intensity Sweep: Latency vs Threads')
	plt.savefig(os.path.join(PLOT_DIR, "intensity_sweep_latency.png"))
	plt.close()

def plot_working_set_sweep(csv_file):
	df = pd.read_csv(csv_file)
	if 'Size_KB' not in df.columns or 'Latency_ns' not in df.columns:
		return
	grouped = df.groupby('Size_KB')['Latency_ns'].agg(['mean','std']).fillna(0)
	plt.figure()
	plt.errorbar(grouped.index, grouped['mean'], yerr=grouped['std'], marker='o', capsize=4)
	plt.xscale('log')
	plt.xlabel('Working Set Size (KB)')
	plt.ylabel('Latency (ns)')
	plt.title('Working Set Size Sweep')
	plt.savefig(os.path.join(PLOT_DIR, "working_set_sweep.png"))
	plt.close()

def plot_cache_miss_impact(csv_file):
	df = pd.read_csv(csv_file)

	# Use the bandwidth directly from CSV
	df['CacheMissRate'] = df['miss_rate']

	# Aggregate mean and std by cache-miss
	grouped = df.groupby('CacheMissRate')['bandwidth_GBps'].agg(['mean','std']).fillna(0)

	plt.figure()
	plt.errorbar(grouped.index, grouped['mean'], yerr=grouped['std'], marker='o', capsize=4)
	plt.xlabel('Cache Miss Rate')
	plt.ylabel('Bandwidth (GB/s)')
	plt.title('Cache Miss Impact on Bandwidth (AMAT-based)')
	os.makedirs(PLOT_DIR, exist_ok=True)
	plt.savefig(os.path.join(PLOT_DIR, "cache_miss_impact.png"))
	plt.close()
	print(f"Plot saved to {os.path.join(PLOT_DIR, 'cache_miss_impact.png')}")

def plot_tlb_impact(csv_file):
	df = pd.read_csv(csv_file)
	if 'PageSize' not in df.columns or 'GBps' not in df.columns:
		return

	grouped = df.groupby('PageSize').agg(['mean','std']).fillna(0)

	# Bandwidth vs Page Size
	plt.figure()
	plt.errorbar(grouped.index, grouped['GBps']['mean'],
				 yerr=grouped['GBps']['std'], marker='o', capsize=4)
	plt.xscale('log', base=2)
	plt.xlabel('Page Size (Bytes)')
	plt.ylabel('Bandwidth (GB/s)')
	plt.title('TLB Impact: Bandwidth vs Page Size')
	plt.savefig(os.path.join(PLOT_DIR, "tlb_impact_bandwidth.png"))
	plt.close()

	# Latency proxy (Time_ms per run) vs Page Size
	plt.figure()
	plt.errorbar(grouped.index, grouped['Time_ms']['mean'],
				 yerr=grouped['Time_ms']['std'], marker='o', capsize=4)
	plt.xscale('log', base=2)
	plt.xlabel('Page Size (Bytes)')
	plt.ylabel('Execution Time (ms)')
	plt.title('TLB Impact: Time vs Page Size')
	plt.savefig(os.path.join(PLOT_DIR, "tlb_impact_time.png"))
	plt.close()

# Run all plots
# plot_zero_queue_latency("results/zero_queue_latency.csv")
# plot_pattern_sweep("results/pattern_sweep.csv")
plot_rw_mix("results/read_write_mix.csv")
# plot_intensity_sweep("results/intensity_sweep.csv")
# plot_working_set_sweep("results/working_set_sweep.csv")
# plot_cache_miss_impact("results/cache_miss_rate.csv")
# plot_tlb_impact("results/tlb_impact.csv")

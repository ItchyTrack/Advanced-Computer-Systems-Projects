import os
import json
import pandas as pd
import numpy as np

# ----------------- Utilities -----------------
def clean_name(name: str) -> str:
	if "(" in name and ")" in name:
		name = name.replace(name[name.find("("): name.find(")") + 1], "")
	replacements = [
		"-D", "-f", "_no-slp-vectorize", "-O3_",
		"-std=c++17_fast-math_", ".csv", "dataOut_"
	]
	for r in replacements:
		name = name.replace(r, "")
	name = name.replace("__", "_")
	return name.rstrip("_")

def load_csv(file_path: str) -> pd.DataFrame | None:
	try:
		df = pd.read_csv(file_path, sep=None, engine="python")
		df.columns = [col.strip() for col in df.columns]
		if {"size", "time"} - set(df.columns):
			print(f"Skipping {file_path}, missing 'size' or 'time' column")
			return None
		return df
	except Exception as e:
		print(f"Failed to read {file_path}: {e}")
		return None

data_dir = "./data"
output_json = "performance_summary2.json"

csv_files = sorted([f for f in os.listdir(data_dir) if f.endswith(".csv")])
if not csv_files:
	print(f"No CSV files found in {data_dir}")
	exit(1)

# Load and clean
data_map = {}
for f in csv_files:
	df = load_csv(os.path.join(data_dir, f))
	if df is not None:
		data_map[f] = df

if not data_map:
	print("No valid CSV files loaded after outlier removal.")
	exit(1)

# Prepare JSON with stats and separate arrays for sizes and times
json_out = {}
for fname in data_map.keys():
	clean_fname = clean_name(fname)
	df:pd.DataFrame = data_map[fname]
	if ("SAXPY" in fname):
		flopPerIndex = 2
	if ("DOT_PRODUCT" in fname):
		flopPerIndex = 2
	if ("ELEMENTWISE_MULTIPLY" in fname):
		flopPerIndex = 1
	if ("STENCIL" in fname):
		flopPerIndex = 5
	gflops = []
	for row in zip(df["size"].tolist(), df["time"].tolist()):
		gflops.append(row[0]/row[1]*flopPerIndex/1000000000)
	json_out[clean_fname] = {
		"sizes": df["size"].tolist(),
		"times": df["time"].tolist(),
		"gflops": gflops
	}

with open(output_json, "w") as f:
	json.dump(json_out, f, indent=2)

print(f"Summary JSON (with outliers removed) saved as {output_json}")

#!/usr/bin/env python3
import subprocess
import os

TESTS = [
    # ("zero_queue_latency.cpp", "zero_queue_latency.csv", "Zero-queue latency"),
    # ("pattern_sweep.cpp", "pattern_sweep.csv", "Pattern & granularity sweep"),
    ("read_write_mix.cpp", "read_write_mix.csv", "Read/Write mix sweep"),
    # ("intensity_sweep.cpp", "intensity_sweep.csv", "Intensity sweep"),
    # ("working_set_sweep.cpp", "working_set_sweep.csv", "Working set sweep"),
    # ("cache_miss_impact.cpp", "cache_miss_impact.csv", "Cache-miss impact"),
    # ("tlb_impact.cpp", "tlb_impact.csv", "TLB-miss impact"),
]

CXX = "clang++"  # Works on macOS (Apple Silicon)
CXXFLAGS = ["-O3", "-std=c++17", "-march=armv8-a", "-Wall"]

BIN_DIR = "bin"


# -----------------------------
# UTILS
# -----------------------------
def compile_test(src: str, binary_path: str) -> bool:
    try:
        subprocess.run(
            [CXX, *CXXFLAGS, src, "-o", binary_path],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        return True
    except subprocess.CalledProcessError as e:
        print(f"[compile error] {src}\n{e.stderr.decode()}")
        return False


def run_test(binary_path: str, csv_path: str) -> bool:
    try:
        result = subprocess.run(
            [binary_path],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        with open(csv_path, "w") as f:
            f.write(result.stdout.decode())
        return True
    except subprocess.CalledProcessError as e:
        print(f"[runtime error] {binary_path}\n{e.stderr.decode()}")
        return False


# -----------------------------
# MAIN
# -----------------------------
def main():
    results_dir = f"results"
    os.makedirs(results_dir, exist_ok=True)
    os.makedirs(BIN_DIR, exist_ok=True)

    print(f"Running {len(TESTS)} benchmarks...\n")

    for src, csv_name, desc in TESTS:
        base = os.path.splitext(os.path.basename(src))[0]
        binary = os.path.join(BIN_DIR, base)
        csv_path = os.path.join(results_dir, csv_name)

        if not os.path.isfile(src):
            print(f"[skip] {src} not found")
            continue

        print(f"{desc} ...", end=" ")
        if not compile_test(src, binary):
            print("compile failed")
            continue
        if not run_test(f"./{binary}", csv_path):
            print("run failed")
            continue
        print("done")

    print(f"\nAll results saved to: {results_dir}")
    print(f"Binaries stored in: {BIN_DIR}")

main()

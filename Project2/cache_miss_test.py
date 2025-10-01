import subprocess

cpp_file = "cache_miss_rate.cpp"
exe_file = "bin/cache_miss_rate"

subprocess.run(["clang++", "-O0", cpp_file, "-o", exe_file])

# Run the benchmark
result = subprocess.run([f"./{exe_file}"], capture_output=True, text=True)
print(result.stdout)

print("CSV output is ready: cache_results.csv")

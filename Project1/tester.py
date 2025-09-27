import subprocess, os, shutil

cpp_file = "project1.cpp"
exe_file = "program.out"

folderOut = "data"

for filename in os.listdir("./" + folderOut):
	file_path = os.path.join("./" + folderOut, filename)
	try:
		if os.path.isfile(file_path) or os.path.islink(file_path):
			os.unlink(file_path)
		elif os.path.isdir(file_path):
			shutil.rmtree(file_path)
	except Exception as e:
		print('Failed to delete %s. Reason: %s' % (file_path, e))

def checkSIMD(dumpName):
	result = subprocess.run(
		["objdump", "-d", exe_file],
		capture_output=True,
		text=True,
		check=True
	)

	binary = result.stdout

	useSIMD = "fadd." in binary or "fmul." in binary or "fmla." in binary
	outFile = f"{folderOut}/dump_{dumpName}{"_SIMD" if useSIMD else ""}"
	with open(outFile, "w") as f:
		f.write(result.stdout)
	return useSIMD

def test(flags:str, sizes, dumpName):
	print(f"Using flags: {flags}")
	compile_process = subprocess.run(
		["clang++"] + flags.split(" ") + [cpp_file, "-o", exe_file],
		capture_output=True,
		text=True
	)

	if compile_process.returncode != 0:
		print(f"Compilation failed:\n{compile_process.stderr}")
		return [], False

	times = []

	usedSIMD = checkSIMD(dumpName)

	for size in sizes:
		run_process = subprocess.run(
			[f"./{exe_file}", format(size, "d")],
			capture_output=True,
			text=True
		)

		if run_process.returncode != 0:
			print(f"Execution failed:\n{run_process.stderr}")
			times.append(0)
		print(f"{size}: {run_process.stdout}, {run_process.stderr}")
		times.append(float(run_process.stdout))

	return times, usedSIMD

def runTest(
		task,
		sizesToDo = list(2**(i+9) for i in range(0, 14))*20,
		oLevel = "-O3",
		noSIMD=False,
		useDouble=False,
		stride2=False,
		stride4=False,
		doMissalignment=False,
		doOddSize=False
):
	stride = 1
	if (stride2): stride *= 2
	if (stride4): stride *= 4
	flags = oLevel + " -std=c++17 -ffast-math -D" + task + f" -DSTRIDE={stride}"
	if (useDouble):
		flags += " -DUSE_DOUBLE"
	if (doMissalignment):
		flags += " -DDO_MISSALIGNMENT"
	if (doOddSize):
		flags += " -DDO_ODD_SIZE"
	if (noSIMD):
		flags += " -fno-slp-vectorize -fno-vectorize"

	times = []
	sizes = []

	sizes += sizesToDo
	timesOut, useSIMD = test(flags, sizesToDo, f"{"_".join(flags.split())}_{min(sizes), max(sizes)}")
	times += timesOut

	# save data
	with open(f"{folderOut}/dataOut_{"_".join(flags.split())}_{min(sizes), max(sizes)}{"_SIMD" if useSIMD else ""}.csv", "w") as f:
		string = "time, size\n"
		for time, size in zip(times, sizes):
			string += f"{time}, {size}\n"
		f.write(string)

import itertools

toPermutate = {"noSIMD": True, "useDouble": True}
keys = list(toPermutate.keys())
for r in range(len(keys) + 1):
	for subset in itertools.combinations(keys, r):
		kwargs = {k: toPermutate[k] for k in subset}
		toPermutateSIMD = {}
		if ("noSIMD" not in kwargs):
			toPermutateSIMD = {"doMissalignment": True, "doOddSize": True}
		keys2 = list(toPermutateSIMD.keys())
		for r2 in range(len(keys2) + 1):
			for subset2 in itertools.combinations(keys2, r2):
				kwargs2 = {k: toPermutateSIMD[k] for k in subset2}
				for task in ["SAXPY", "DOT_PRODUCT", "ELEMENTWISE_MULTIPLY", "STENCIL"]:
					print("Running with params:", kwargs, kwargs2)
					runTest(task, **kwargs, **kwargs2)
					# runTest(task, sizesToDo=list(range(100000000, 1000000000, 100000000)), **kwargs)

toPermutate = {"noSIMD": True, "stride2": True, "stride4": True}
keys = list(toPermutate.keys())
for r in range(len(keys) + 1):
	for subset in itertools.combinations(keys, r):
		kwargs = {k: toPermutate[k] for k in subset}
		# toPermutateSIMD = {}
		if (("stride2" not in kwargs) and ("stride4" not in kwargs)): continue
		# 	toPermutateSIMD = {"doMissalignment": True, "doOddSize": True}
		keys2 = list(toPermutateSIMD.keys())
		for r2 in range(len(keys2) + 1):
			for subset2 in itertools.combinations(keys2, r2):
				kwargs2 = {k: toPermutateSIMD[k] for k in subset2}
				for task in ["SAXPY", "DOT_PRODUCT", "ELEMENTWISE_MULTIPLY", "STENCIL"]:
					print("Running with params:", kwargs, kwargs2)
					runTest(task, **kwargs, **kwargs2)

import pngPlotter

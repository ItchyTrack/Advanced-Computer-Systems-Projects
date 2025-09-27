#import "@preview/oxifmt:1.0.0": strfmt
#import "@preview/lilaq:0.4.0" as lq
#import "@preview/statastic:1.0.0"

#set text(
	13pt
)

#align(center,
	[
		#text([*SIMD Advantage Profiling*], size:20pt)\
		#text([ECSE 4320], size:15pt)\
		#text([Ben Herman], size:15pt)
	]
)

We are trying to test how does SIMD improves the speed code.

#table(
	columns: (auto, auto),
	inset: 10pt,
	align: horizon,
	table.header(
		[*Test Parameter*], [*Description*],
	),
	[Simd], [Tests with compiler auto-vectorization (SIMD instructions like fadd/fmul/fmla).\ Otherwise #text(size: 12pt, `-fno-slp-vectorize -fno-vectorize`) is used.],
	[Saxpy], [Computes `out = in1 * a + in2`.],
	[Dot Product], [Computes `out += in1 * in2`.],
	[Elementwise Multiply], [Computes `out = in1 * in2`.],
	[Stencil], [Computes `out = in1*c1 + in2*c2 + in3*c3`.],
	[Use Double], [Switches all computation from using `floats` (32-bit) to using `doubles` (64-bit).],
	[Missalignment], [Forces deliberately misaligned memory allocation by offsetting pointers.],
	[Odd Size], [Adds 1 to array size so the size is not a divisible two.],
	[Stride], [Different memory access stride patterns (1, 2, 4, 8). We make sure that the total number of operations is still the same.\
	Defaluts to 1],
)

#pagebreak()

=== Compilation Flags:
- -O3: enables aggressive optimization for speed.
- -ffast-math: allows more reordering of floating point operations which improves.
- -std=c++17: ensures compatibility with modern C++ features used in the code.

=== Number of Runs and Array Sizes:
- Array sizes range from 2^9 to 2^22 elements.
- Each array size is tested 20 times.

=== Timing Measurement:
- Execution time is measured using std::chrono::high_resolution_clock.

=== SIMD Detection:
- If SIMD instructions were used is done by checking if ASM produced with objdump contains instructions like \"`fadd.`\", \"`fmul.`\", or \"`fmla.`\"

=== Conditions:
- Model: M2 Mac
- OS: Sequoia 15.6
- Powersource: Wall outlet
- Ram: 16 GB
- Temperature: \~65#sym.degree Fahrenheit

#pagebreak()


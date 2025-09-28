#import "@preview/oxifmt:1.0.0": strfmt
#import "@preview/lilaq:0.4.0" as lq
#import "@preview/statastic:1.0.0"

#set page(
	margin: 0.1in,
	width: 5in,
	height: 5in
)

#set text(
	13pt
)

#let data = json("performance_summary2.json")

#let arrayMedian(arr, backupValue) = {
  	let col = arr.sorted()
  	let len = col.len()
	if (len == 0) { return backupValue }
  	if calc.rem(len, 2) == 0 {
    	let middle = calc.quo(len, 2)
			(col.at(middle - 1) + col.at(middle)) / 2
  	} else {
    	let middle = calc.quo(len, 2)
    	col.at(middle)
  	}
}

#let bin-errors(x-values, y-values) = {
	let unique-x = x-values.dedup()
	unique-x.map(u => {
		let ys = y-values.zip(x-values)
		.filter(p => p.at(1) == u)
		.map(p => p.at(0))

		// remove outliers using 1.5*IQR rule
		let sorted-ys = ys.sorted()
		let q2 = arrayMedian(sorted-ys, 0)
		let q1 = arrayMedian(sorted-ys.filter(y => y < q2), q2)
		let q3 = arrayMedian(sorted-ys.filter(y => y > q2), 12)
		let iqr = q3 - q1
		let ys-clean = ys.filter(y => y >= q1 - 1.5*iqr and y <= q3 + 1.5*iqr)

		let n = ys-clean.len()
		let mean = statastic.arrayAvg(ys-clean)
		let stddev = statastic.arrayStd(ys-clean)
		let stderr = stddev / calc.sqrt(n)

		(u, mean, stderr, ys-clean)
	})
}

#let doublePrint(item) = align(center, block(breakable:false,  {
	let SIMDData = data.at(item + "_SIMD")
	let notSIMDData = data.at(item + "_no-vectorize")
	[
		= #item.replace("_DO_", ",_").replace("_USE_", ",_").replace("_STRIDE=1", "").replace("_STRIDE=", ",_STRIDE=").split("_").map(x=>" "+ x.at(0) + lower(x.slice(1))).join() #v(-0.1cm)
		#lq.diagram(
			xscale: lq.scale.log(base: 2),
			yscale: lq.scale.log(base: 2),
			legend: (position: top+left, fill: none, inset:0em, stroke: none),
			width: 3in,
			height: 3in,
			xlabel: [Array Size],
			ylabel: [Time (seconds)],
			xaxis: (auto-exponent-threshold: 0),
			yaxis: (auto-exponent-threshold: 0),
			// SIMDData
			let data = bin-errors(SIMDData.at("sizes"), SIMDData.at("times")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:blue, size: 0.2in, label: [SIMD]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:blue
			),
			let (slope1, intercept1, r_squared1) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
			lq.line(
				stroke: (paint: blue),
				(lq.cmin(u), lq.cmin(mean)),
				(lq.cmax(u), slope1*lq.cmax(u)),
				clip: true
			),
			// notSIMDData
			let data = bin-errors(notSIMDData.at("sizes"), notSIMDData.at("times")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:orange, size: 0.2in, label: [Not SIMD]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:orange
			),
			let (slope2, intercept2, r_squared2) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
			lq.line(
				stroke: (paint: orange),
				(lq.cmin(u), lq.cmin(mean)),
				(lq.cmax(u), slope2*lq.cmax(u)),
				clip: true
			)
		)\
		#align(left)[
			$
			"With SIMD: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope1)\
			"Without SIMD: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope2)\
			$
		]
		Speedup: #{slope2/slope1}
	]
}))
#let print(item) = align(center, block(breakable:false,  {
	let SIMDData = data.at(item)
	[
		= #item.replace("_SIMD", "").replace("_DO_", ",_").replace("_STRIDE=1", "").replace("STRIDE=", ",_=").replace("_USE_", ",_").split("_").map(x=>" "+ x.at(0) + lower(x.slice(1))).join() #v(0cm)
		#lq.diagram(
			xscale: lq.scale.log(base: 2),
			yscale: lq.scale.log(base: 2),
			width: 3in,
			height: 3in,
			xlabel: [Array Size],
			ylabel: [Time (seconds)],
			xaxis: (auto-exponent-threshold: 0),
			yaxis: (auto-exponent-threshold: 0),
			let data = bin-errors(SIMDData.at("sizes"), SIMDData.at("times")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:blue, size: 0.2in, label: [SIMD]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:blue
			),
			let (slope, intercept, r_squared) = statastic.arrayLinearRegression(xs, ys.flatten()),
			lq.line(
				stroke: (paint: blue),
				(lq.cmin(u), lq.cmin(mean)),
				(lq.cmax(xs), slope*lq.cmax(xs)),
				clip: true
			)
		)\
		#align(left)[
			$
			"With SIMD: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope)\
			$
		]
	]
}))
#let doublePrintGFLOPS(item) = align(center, block(breakable:false,  {
	let SIMDData = data.at(item + "_SIMD")
	let notSIMDData = data.at(item + "_no-vectorize")
	[
		= #item.replace("_DO_", ",_").replace("_USE_", ",_").replace("_STRIDE=1", "").replace("_STRIDE=", ",_STRIDE=").split("_").map(x=>" "+ x.at(0) + lower(x.slice(1))).join() #v(-0.1cm)
		#lq.diagram(
			xscale: lq.scale.log(base: 2),
			yscale: lq.scale.log(base: 2),
			legend: (position: top+right, fill: none, inset:0em, stroke: none),
			width: 3in,
			height: 3in,
			xlabel: [Array Size],
			ylabel: [GFLOPS],
			xaxis: (auto-exponent-threshold: 0),
			yaxis: (auto-exponent-threshold: 0),
			// SIMDData
			let data = bin-errors(SIMDData.at("sizes"), SIMDData.at("gflops")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:blue, size: 0.2in, label: [SIMD]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:blue
			),
			let (slope1, intercept1, r_squared1) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
			// lq.line(
			// 	stroke: (paint: blue),
			// 	(lq.cmin(u), lq.cmin(mean)),
			// 	(lq.cmax(u), slope1*lq.cmax(u)),
			// 	clip: true
			// ),
			// notSIMDData
			let data = bin-errors(notSIMDData.at("sizes"), notSIMDData.at("gflops")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:orange, size: 0.2in, label: [Not SIMD]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:orange
			),
			let (slope2, intercept2, r_squared2) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
			// lq.line(
			// 	stroke: (paint: orange),
			// 	(lq.cmin(u), lq.cmin(mean)),
			// 	(lq.cmax(u), slope2*lq.cmax(u)),
			// 	clip: true
			// )
		)\
		#align(left)[
			$
			"With SIMD: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope1)\
			"Without SIMD: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope2)\
			$
		]
		Speedup: #{slope2/slope1}
	]
}))
#let printGFLOPS_STRIDE(item) = align(center, block(breakable:false,  {
	let SIMDData1 = data.at(item.replace("_STRIDE=2", "_STRIDE=1"))
	let SIMDData2 = data.at(item)
	let SIMDData3 = data.at(item.replace("_STRIDE=2", "_STRIDE=4"))
	if (data.keys().contains(item.replace("_STRIDE=2", "_STRIDE=8"))) {
		let SIMDData4 = data.at(item.replace("_STRIDE=2", "_STRIDE=8"))
		[
		= #item.replace("_DO_", ",_").replace("_USE_", ",_").replace("_STRIDE=2", "").replace("_SIMD", "").split("_").map(x=>" "+ x.at(0) + lower(x.slice(1))).join():\ Strides:1,2,4,8 #v(-0.1cm)
		#lq.diagram(
			xscale: lq.scale.log(base: 2),
			yscale: lq.scale.log(base: 2),
			legend: (position: top+right, fill: none, inset:0em, stroke: none),
			width: 3in,
			height: 3in,
			xlabel: [Array Size],
			ylabel: [GFLOPS],
			xaxis: (auto-exponent-threshold: 0),
			yaxis: (auto-exponent-threshold: 0),
			// 1
			let data = bin-errors(SIMDData1.at("sizes"), SIMDData1.at("gflops")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:blue, size: 0.2in, label: [Stride=1]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:blue
			),
			let (slope1, intercept1, r_squared1) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
			// 2
			let data = bin-errors(SIMDData2.at("sizes"), SIMDData2.at("gflops")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:orange, size: 0.2in, label: [Stride=2]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:orange
			),
			let (slope2, intercept2, r_squared2) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
			// 4
			let data = bin-errors(SIMDData3.at("sizes"), SIMDData3.at("gflops")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:green, size: 0.2in, label: [Stride=4]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:green
			),
			let (slope3, intercept3, r_squared3) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
			// 8
			let data = bin-errors(SIMDData4.at("sizes"), SIMDData4.at("gflops")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:yellow, size: 0.2in, label: [Stride=8]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:yellow
			),
			let (slope4, intercept4, r_squared4) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
		)\
		#align(left)[
			$
			"Stride=1: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope1)\
			"Stride=2: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope2)\
			"Stride=4: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope3)\
			"Stride=8: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope4)\
			$
		]
	]
	} else {
		let SIMDData4 = data.at(item.replace("_STRIDE=2", "_STRIDE=8").replace("_SIMD", "_no-vectorize"))
		[
		= #item.replace("_DO_", ",_").replace("_USE_", ",_").replace("_STRIDE=2", "").replace("_SIMD", "").split("_").map(x=>" "+ x.at(0) + lower(x.slice(1))).join():\ Strides:1,2,4,8 #v(-0.1cm)
		#lq.diagram(
			xscale: lq.scale.log(base: 2),
			yscale: lq.scale.log(base: 2),
			legend: (position: top+right, fill: none, inset:0em, stroke: none),
			width: 3in,
			height: 3in,
			xlabel: [Array Size],
			ylabel: [GFLOPS],
			xaxis: (auto-exponent-threshold: 0),
			yaxis: (auto-exponent-threshold: 0),
			// 1
			let data = bin-errors(SIMDData1.at("sizes"), SIMDData1.at("gflops")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:blue, size: 0.2in, label: [Stride=1]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:blue
			),
			let (slope1, intercept1, r_squared1) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
			// 2
			let data = bin-errors(SIMDData2.at("sizes"), SIMDData2.at("gflops")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:orange, size: 0.2in, label: [Stride=2]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:orange
			),
			let (slope2, intercept2, r_squared2) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
			// 4
			let data = bin-errors(SIMDData3.at("sizes"), SIMDData3.at("gflops")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:green, size: 0.2in, label: [Stride=4]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:green
			),
			let (slope3, intercept3, r_squared3) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
			// 8
			let data = bin-errors(SIMDData4.at("sizes"), SIMDData4.at("gflops")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:yellow, size: 0.2in, label: [Stride=8 (NOT SIMD)]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:yellow
			),
			let (slope4, intercept4, r_squared4) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
		)\
		#align(left)[
			$
			"Stride=1: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope1)\
			"Stride=2: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope2)\
			"Stride=4: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope3)\
			"Stride=8: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope4)\
			$
		]
	]
}}))
#let printGFLOPS(item) = align(center, block(breakable:false,  {
	let SIMDData = data.at(item)
	let SIMDDataRemoveOtherFlags = data.at(item.replace("_USE_DOUBLE", "").replace("_DO_MISSALIGNMENT", "").replace("_DO_ODD_SIZE", ""))
	let flags = ""
	let nflags = ""
	if (item.contains("_USE_DOUBLE")) {
		flags += "Double"
		nflags += "Float"
	}
	if (item.contains("_DO_MISSALIGNMENT")) {
		if (flags.len() != 0) {
			flags += ", "
			nflags += ", "
		}
		flags += "Misaligned"
		nflags += "Aligned"
	}
	if (item.contains("_DO_ODD_SIZE")) {
		if (flags.len() != 0) {
			flags += ", "
			nflags += ", "
		}
		flags += "Odd Length"
		nflags += "SIMD Aligned Length"
	}
	[
		= #item.replace("_USE_DOUBLE", "").replace("_DO_MISSALIGNMENT", "").replace("_DO_ODD_SIZE", "").replace("_SIMD", "").replace("_DO_", ",_").replace("_STRIDE=1", "").replace("STRIDE=", ",_=").replace("_USE_", ",_").split("_").map(x=>" "+ x.at(0) + lower(x.slice(1))).join():\ #flags vs #nflags #v(0cm)
		#lq.diagram(
			xscale: lq.scale.log(base: 2),
			yscale: lq.scale.log(base: 2),
			width: 3in,
			height: 3in,
			xlabel: [Array Size],
			ylabel: [GFLOPS],
			xaxis: (auto-exponent-threshold: 0),
			yaxis: (auto-exponent-threshold: 0),
			// with flags
			let data = bin-errors(SIMDData.at("sizes"), SIMDData.at("gflops")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:blue, size: 0.2in, label: [#flags]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:blue
			),
			let (slope1, intercept, r_squared) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
			// lq.line(
			// 	stroke: (paint: blue),
			// 	(lq.cmin(u), lq.cmin(mean)),
			// 	(lq.cmax(xs), slope*lq.cmax(xs)),
			// 	clip: true
			// )
			// without flags
			let data = bin-errors(SIMDDataRemoveOtherFlags.at("sizes"), SIMDDataRemoveOtherFlags.at("gflops")),
			let u = data.map(x=>x.at(0)),
			let mean = data.map(x=>x.at(1)),
			let stderr = data.map(x=>x.at(2)),
			let ys = data.map(x=>x.at(3)),
			lq.plot(
				u,
				mean,
				stroke: none,
				mark-size: 0pt,
				yerr: stderr,
				z-index: 10,
				color: black
			),
			lq.scatter((), (), color:orange, size: 0.2in, label: [#nflags]),
			let xs = u.zip(ys).map((x)=>range(x.at(1).len()).map(_=>x.at(0))).flatten(),
			lq.scatter(
				xs,
				ys.flatten(),
				color:orange
			),
			let (slope2, intercept, r_squared) = statastic.arrayLinearRegression(xs, ys.flatten()).values(),
		)\
		#align(left)[
			$
			"With SIMD: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope1)\
			"With SIMD: " & "GFLOPS"=("arraySize")*#strfmt("({0:.4e})", slope2)\
			$
		]
	]
}))

#for item in data {
	if (item.at(0).contains("SIMD")) {
		if (item.at(0).contains("DO_MISSALIGNMENT") or item.at(0).contains("ODD_SIZE")) {} else {
			// doublePrint(item.at(0).replace("_SIMD", ""))
			doublePrintGFLOPS(item.at(0).replace("_SIMD", ""))
		}
	}
}
#set page(
	margin: 0.1in,
	width: 5in,
	height: 5.3in
)
#for item in data {
	if (item.at(0).contains("SIMD")) {
		if (item.at(0).contains("DO_MISSALIGNMENT") or item.at(0).contains("ODD_SIZE")) {
			printGFLOPS(item.at(0))
		}
	}
}
#set page(
	margin: 0.1in,
	width: 5in,
	height: 5.9in
)
#for item in data {
	if (item.at(0).contains("SIMD")) {
		if (item.at(0).contains("_STRIDE=2")) {
			printGFLOPS_STRIDE(item.at(0))
		}
	}
}

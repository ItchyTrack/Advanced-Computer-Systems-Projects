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

// #align(center,
// 	[
// 		#text([*SIMD Advantage Profiling*], size:20pt)\
// 		#text([Ben Herman], size:15pt)
// 	]
// )

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
			"With SIMD: " & ("arraySize")*#strfmt("({0:.4e})", slope1)\
			"Without SIMD: " & ("arraySize")*#strfmt("({0:.4e})", slope2)\
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
			"With SIMD: " & ("arraySize")*#strfmt("({0:.4e})", slope)\
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
			"With SIMD: " & ("arraySize")*#strfmt("({0:.4e})", slope1)\
			"Without SIMD: " & ("arraySize")*#strfmt("({0:.4e})", slope2)\
			$
		]
		Speedup: #{slope2/slope1}
	]
}))
#let printGFLOPS(item) = align(center, block(breakable:false,  {
	let SIMDData = data.at(item)
	[
		= #item.replace("_SIMD", "").replace("_DO_", ",_").replace("_STRIDE=1", "").replace("STRIDE=", ",_=").replace("_USE_", ",_").split("_").map(x=>" "+ x.at(0) + lower(x.slice(1))).join() #v(0cm)
		#lq.diagram(
			xscale: lq.scale.log(base: 2),
			yscale: lq.scale.log(base: 2),
			width: 3in,
			height: 3in,
			xlabel: [Array Size],
			ylabel: [GFLOPS],
			xaxis: (auto-exponent-threshold: 0),
			yaxis: (auto-exponent-threshold: 0),
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
			let (slope, intercept, r_squared) = statastic.arrayLinearRegression(xs, ys.flatten()),
			// lq.line(
			// 	stroke: (paint: blue),
			// 	(lq.cmin(u), lq.cmin(mean)),
			// 	(lq.cmax(xs), slope*lq.cmax(xs)),
			// 	clip: true
			// )
		)\
		#align(left)[
			$
			"With SIMD: " & ("arraySize")*#strfmt("({0:.4e})", slope)\
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
	height: 4.3in
)
#for item in data {
	if (item.at(0).contains("SIMD")) {
		if (item.at(0).contains("DO_MISSALIGNMENT") or item.at(0).contains("ODD_SIZE")) {
			if (item.at(0).len() > 52) {
				set page(
					margin: 0.1in,
					width: 5in,
					height: 4.6in
				)
				// print(item.at(0))
				printGFLOPS(item.at(0))
			} else {
				// print(item.at(0))
				printGFLOPS(item.at(0))
			}
		}
	}
}

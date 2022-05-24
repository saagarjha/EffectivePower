//
//  HistogramGraph.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/23/22.
//

import SwiftUI

protocol HistogramGraphable {
	var value: Double { get }
	var position: ClosedRange<Double> { get }
}

struct HistogramGraphView<T: Identifiable & HistogramGraphable, I: Equatable>: View, Equatable {
	class HistogramSubgraph: Identifiable {
		let range: ClosedRange<Double>
		let value: Double

		init(range: ClosedRange<Double>, value: Double) {
			self.range = range
			self.value = value
		}
	}

	let horizontalBounds: ClosedRange<Double>
	let values: [T]
	let color: Color
	let identityToken: I

	var body: some View {
		GeometryReader { geometry in
			Path { path in
				let histogram = smoothHistogram(divisions: Int(geometry.size.width) / 250 * 10)
				guard let max = histogram.map(\.value).max() else {
					return
				}
				let verticalBounds = 0...max

				path.move(to: .init(x: 0, y: geometry.size.height))
				for histogramSubgraph in histogram {
					let width = (histogramSubgraph.range.upperBound - histogramSubgraph.range.lowerBound) / (horizontalBounds.upperBound - horizontalBounds.lowerBound) * geometry.size.width
					let offset = (histogramSubgraph.range.lowerBound - horizontalBounds.lowerBound) / (horizontalBounds.upperBound - horizontalBounds.lowerBound) * geometry.size.width
					let height = (verticalBounds.upperBound - histogramSubgraph.value) / (verticalBounds.upperBound - verticalBounds.lowerBound) * geometry.size.height

					path.addLine(to: .init(x: offset, y: geometry.size.height))
					path.addLine(to: .init(x: offset, y: height))
					path.addLine(to: .init(x: offset + width, y: height))
					path.addLine(to: .init(x: offset + width, y: geometry.size.height))

				}
				path.move(to: .init(x: geometry.size.width, y: geometry.size.height))
				path.closeSubpath()
			}
			.fill(color)
		}
	}

	func histogram() -> [HistogramSubgraph] {
		var controlPoints = [Double: ([T], [T])]()

		for value in values {
			controlPoints[value.position.lowerBound, default: ([], [])].0.append(value)
			controlPoints[value.position.upperBound, default: ([], [])].1.append(value)
		}

		var histogram = [HistogramSubgraph]()
		var current = [T.ID: T]()
		let controlPointValues = controlPoints.keys.sorted()
		for (low, high) in zip(controlPointValues, controlPointValues.dropFirst()) {
			for value in controlPoints[low]!.0 {
				current[value.id] = value
			}
			var total: Double = 0
			for value in current.values {
				total += value.value * (high - low) / (value.position.upperBound - value.position.lowerBound)
				assert(!total.isNaN)
			}
			histogram.append(HistogramSubgraph(range: low...high, value: total))
			for value in controlPoints[high]!.1 {
				current.removeValue(forKey: value.id)
			}
		}
		return histogram
	}

	func smoothHistogram(divisions: Int) -> [HistogramSubgraph] {
		let histogram = histogram()
		var smoothHistogram = [HistogramSubgraph]()

		var index = histogram.startIndex
		for i in 0..<divisions {
			let start = horizontalBounds.lowerBound + Double(i) / Double(divisions) * (horizontalBounds.upperBound - horizontalBounds.lowerBound)
			let end = horizontalBounds.lowerBound + Double(i + 1) / Double(divisions) * (horizontalBounds.upperBound - horizontalBounds.lowerBound)
			guard
				let _index = histogram[index...].firstIndex(where: {
					$0.range.contains(start)
				})
			else {
				continue
			}
			index = _index
			let endIndex =
				histogram[index...].firstIndex {
					$0.range.contains(end)
				} ?? histogram.index(before: histogram.endIndex)
			smoothHistogram.append(
				HistogramSubgraph(
					range: start...end,
					value: histogram[index...endIndex].reduce(0) { partial, new in
						let intersection = max(start, new.range.lowerBound)...min(end, new.range.upperBound)
						return partial + new.value * (intersection.upperBound - intersection.lowerBound) / (new.range.upperBound - new.range.lowerBound)
					}))
			index = endIndex
		}

		return smoothHistogram
	}

	static func == (lhs: HistogramGraphView, rhs: HistogramGraphView) -> Bool {
		lhs.identityToken == rhs.identityToken && lhs.horizontalBounds == rhs.horizontalBounds && lhs.color == rhs.color
	}
}

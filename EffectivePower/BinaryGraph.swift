//
//  BinaryGraph.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/23/22.
//

import SwiftUI

protocol BinaryGraphable {
	var value: Bool { get }
	var position: Double { get }
}

struct BinaryGraphView<T: Identifiable & Hashable & BinaryGraphable, I: Equatable>: View, Equatable {
	let bounds: ClosedRange<Double>
	let values: [T]
	let color: Color
	let identityToken: I

	var body: some View {
		GeometryReader { geometry in
			let importantValues = importantValues()
			ForEach(Array(zip(importantValues, importantValues.dropFirst())), id: \.0) { (value, next) in
				subgraph(start: value.position, end: next.position, value: value.value, in: geometry)
			}
		}
	}

	func importantValues() -> [T] {
		[values.first!]
			+ zip(values, values.dropFirst()).filter {
				$0.0.value != $0.1.value
			}.map(\.1) + [values.last!]
	}

	func subgraph(start: Double, end: Double, value: Bool, in geometry: GeometryProxy) -> some View {
		let width = (end - start) / (bounds.upperBound - bounds.lowerBound) * geometry.size.width
		let offset = (start - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound) * geometry.size.width
		return Rectangle()
			.fill(value ? color : .clear)
			.position(x: offset + width / 2, y: geometry.size.height / 2)
			.frame(width: width, height: geometry.size.height)
	}

	static func == (lhs: BinaryGraphView, rhs: BinaryGraphView) -> Bool {
		lhs.identityToken == rhs.identityToken && lhs.bounds == rhs.bounds && lhs.color == rhs.color
	}
}

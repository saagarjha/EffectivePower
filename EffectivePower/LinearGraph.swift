//
//  LinearGraph.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/23/22.
//

import SwiftUI

protocol LinearGraphable {
	var value: Double { get }
	var position: Double { get }
}

struct LinearGraphView<T: Identifiable & LinearGraphable, I: Equatable>: View, Equatable {
	let horizontalBounds: ClosedRange<Double>
	let verticalBounds: ClosedRange<Double>
	let values: [T]
	let color: Color
	let identityToken: I

	var body: some View {
		GeometryReader { geometry in
			Path { path in
				var first = true
				for value in values {
					let point: CGPoint = .init(x: (value.position - horizontalBounds.lowerBound) / (horizontalBounds.upperBound - horizontalBounds.lowerBound) * geometry.size.width, y: (verticalBounds.upperBound - value.value) / (verticalBounds.upperBound - verticalBounds.lowerBound) * geometry.size.height)
					if first {
						path.move(to: point)
					} else {
						path.addLine(to: point)
					}
					first = false
				}
			}
			.stroke(color)
		}
	}

	static func == (lhs: LinearGraphView, rhs: LinearGraphView) -> Bool {
		return lhs.identityToken == rhs.identityToken && lhs.horizontalBounds == rhs.horizontalBounds && lhs.color == rhs.color
	}
}

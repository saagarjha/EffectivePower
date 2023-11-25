//
//  ChartView.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/23/22.
//

import SwiftUI

struct ChartView: View {
	let document: EffectivePowerDocument

	@Binding
	var magnification: CGFloat
	@GestureState
	var partialMagnification: CGFloat = 1
	@Binding
	var selectedRange: ClosedRange<TimeInterval>?
	@Binding
	var selectedNodes: Set<CompleteNode.ID>
	@State
	var location: CGPoint?

	static let overlayFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		return formatter
	}()

	var body: some View {
		GeometryReader { geometry in
			ZStack {
				let bounds = document.bounds.lowerBound.timeIntervalSince1970...document.bounds.upperBound.timeIntervalSince1970
				let width = geometry.size.width * magnification * partialMagnification
				ScrollView(.horizontal) {
					ZStack {
						// Hide when in a gesture, because drawing this is slow
						if partialMagnification == 1 {
							let selectedEvents =
								!selectedNodes.isEmpty
								? document.events.filter {
									selectedNodes.contains($0.completeNode.id)
								} : nil
							HistogramGraphView(horizontalBounds: bounds, values: document.events, filteredValues: selectedEvents, color: .graph, filterColor: .filteredGraph, identityToken: selectedNodes)
								.equatable()
								.frame(width: width)
						}
						BinaryGraphView(bounds: bounds, values: document.batteryStatuses, color: Color.green.opacity(0.5), identityToken: document)
							.equatable()
							.frame(width: width)
						LinearGraphView(horizontalBounds: bounds, verticalBounds: 0...100, values: document.batteryStatuses, color: Color.foregroundish, identityToken: document)
							.equatable()
							.frame(width: width)
						if let selectedRange = selectedRange {
							let start = max((selectedRange.lowerBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound) * width, 0)
							let end = min((selectedRange.upperBound - bounds.lowerBound) / (bounds.upperBound - bounds.lowerBound) * width, width)
							let veilColor = Color.backgroundish.opacity(0.5)
							let boundColor = Color.foregroundish
							Rectangle()
								.fill(veilColor)
								.frame(width: start, height: geometry.size.height)
								.position(x: start / 2, y: geometry.size.height / 2)
							Path { path in
								path.move(to: .init(x: start, y: 0))
								path.addLine(to: .init(x: start, y: geometry.size.height))
							}.stroke(boundColor)
							Rectangle()
								.fill(veilColor)
								.frame(width: width - end, height: geometry.size.height)
								.position(x: end + (width - end) / 2, y: geometry.size.height / 2)
							Path { path in
								path.move(to: .init(x: end, y: 0))
								path.addLine(to: .init(x: end, y: geometry.size.height))
							}
							.stroke(boundColor)

						}

						MouseTrackingView(location: $location)

						if let location = location {
							Path { path in
								path.move(to: .init(x: location.x, y: 0))
								path.addLine(to: .init(x: location.x, y: geometry.size.height))
							}
							.stroke(style: StrokeStyle(dash: [5]))
							.stroke(Color.foregroundish)
						}
					}
					.gesture(
						MagnificationGesture()
							.updating($partialMagnification) { new, old, _ in
								old = normalizePartialMagnification(new)
							}
							.onEnded {
								magnification *= normalizePartialMagnification($0)
								withAnimation {
									magnification = max(1, magnification)
								}
							}
					)
					.gesture(
						DragGesture()
							.onChanged {
								let drag = CGRect(origin: $0.startLocation, size: $0.translation).standardized
								selectedRange = (bounds.lowerBound + drag.minX / width * (bounds.upperBound - bounds.lowerBound))...((bounds.lowerBound + drag.maxX / width * (bounds.upperBound - bounds.lowerBound)))
								location = $0.location
							}
					)
					.gesture(
						TapGesture()
							.onEnded {
								selectedRange = nil
							}
					)
				}.frame(width: geometry.size.width)
				if let location = location {
					// Hack to align the view to the bottom right corner
					HStack {
						VStack {
							Spacer()
							let time = bounds.lowerBound + (location.x / width) * (bounds.upperBound - bounds.lowerBound)
							let closestBatteryStatus = document.batteryStatuses.min {
								abs($0.timestamp.timeIntervalSince1970 - time) < abs($1.timestamp.timeIntervalSince1970 - time)
							}!
							let earlierUnlock = document.unlockedIntervals.lowerBound(of: time, transform: \.duration.lowerBound.timeIntervalSince1970)
							let laterUnlock = document.unlockedIntervals.upperBound(of: time, transform: \.duration.upperBound.timeIntervalSince1970)

							HStack {
								HStack {
									Image(systemName: "clock.fill")
									Text("\(Date(timeIntervalSince1970: time), formatter: Self.overlayFormatter)")
										.font(.title3.monospacedDigit())
								}
								Divider()
								Image(systemName: earlierUnlock != laterUnlock ? "lock.open.fill" : "lock.fill")
								Divider()
								HStack {
									Image(systemName: closestBatteryStatus.charging ? "battery.100.bolt" : "battery.100")
									Text(String(format: "%.0f%%", closestBatteryStatus.level))
										.font(.title3.monospacedDigit())
								}
							}
							.padding()
							.fixedSize(horizontal: false, vertical: true)
							.materialBackground()
							.cornerRadius(8)
						}
						Spacer()
					}
					.padding(20)
				}
			}
		}
		.background(Color.backgroundish)
	}

	func normalizePartialMagnification(_ partialMagnification: CGFloat) -> CGFloat {
		if magnification * partialMagnification < 1 {
			return 1 - pow(1 - partialMagnification, 2)
		} else {
			return partialMagnification
		}
	}
}

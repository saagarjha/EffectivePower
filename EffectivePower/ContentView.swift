//
//  ContentView.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/8/22.
//

import SwiftUI

struct ContentView: View {
	@Binding
	var document: EffectivePowerDocument

	@State
	var magnification: CGFloat = 1
	@State
	var selectedRange: ClosedRange<TimeInterval>? = nil
	@State
	var selectedNodes: Set<CompleteNode.ID> = []

	var body: some View {
		let chartView = ChartView(document: document, magnification: $magnification, selectedRange: $selectedRange, selectedNodes: $selectedNodes)
		let usageView = UsageView(events: document.events, selectedRange: $selectedRange, selectedNodes: $selectedNodes)
			.frame(minWidth: 300, idealWidth: 300, maxWidth: 300)
		let contentView = Group {
			if #available(macOS 14.0, *) {
				chartView.inspector(isPresented: .constant(true)) {
					usageView
				}
			} else {
				HStack(spacing: 0) {
					chartView
					usageView
				}
			}
		}

		// View builders make this really annoying
		if let deviceModel = document.deviceModel,
			let deviceBuild = document.deviceBuild
		{
			contentView.navigationSubtitle("\(document.deviceName ?? "<Unknown>") (\(deviceModel), \(deviceBuild))")
		} else {
			contentView.navigationSubtitle("\(document.batteryStatuses.count + document.events.count) samples")
		}
	}
}

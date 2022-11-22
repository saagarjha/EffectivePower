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
	var selectedNodes: Set<Node.ID> = []
    
    @State
    var specificApp: String
    
    @State
    var specificRootNode: String
    
	var body: some View {
		let splitView = HSplitView {
			ChartView(document: document, magnification: $magnification, selectedRange: $selectedRange)
            UsageView(events: document.events, selectedRange: $selectedRange, selectedNodes: $selectedNodes, specificApp: specificApp, specificRootNode: specificRootNode)
				.listStyle(.sidebar)
				.frame(minWidth: 500, idealWidth: 500, maxWidth: 500)
		}
		.toolbar {
			Spacer()
            HStack {
                TextField("filter app", text: $specificApp)
                TextField("filter category", text: $specificRootNode)
            }
            Slider(value: $magnification, in: 0.2...20)
				.frame(width: 100)
		}

		// View builders make this really annoying
		if let deviceModel = document.deviceModel,
			let deviceBuild = document.deviceBuild
		{
			splitView.navigationSubtitle("\(document.deviceName ?? "<Unknown>") (\(deviceModel), \(deviceBuild))")
		} else {
			splitView.navigationSubtitle("\(document.batteryStatuses.count + document.events.count) samples")
		}
	}
}

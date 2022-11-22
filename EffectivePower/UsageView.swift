//
//  UsageView.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/23/22.
//

import SwiftUI

struct UsageView: View {
	let events: [Event]
	@Binding
	var selectedRange: ClosedRange<TimeInterval>?
	@Binding
	var selectedNodes: Set<Node.ID>
    
    @State
    var showsAlert = false
    
    @State
    var copiedContent = ""
    
    var specificApp: String
    var specificRootNode: String

	static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .none
		dateFormatter.timeStyle = .medium
		return dateFormatter
	}()

	struct NodePresentation: Hashable, Identifiable {
		let node: Node?
		let rootNode: Node?

		var id: String {
			(node?.id ?? "") + " " + (rootNode?.id ?? "")
		}
	}

	var body: some View {
		let selectedRange = selectedRange ?? Date.distantPast.timeIntervalSince1970...Date.distantFuture.timeIntervalSince1970
		let matchingEvents = events.filter { event in
			let start = max(event.timestamp.lowerBound.timeIntervalSince1970, selectedRange.lowerBound)
			let end = min(event.timestamp.upperBound.timeIntervalSince1970, selectedRange.upperBound)
            let conditionTime = start < end
            let conditionApp = specificApp == "" ? true : event.node?.name == specificApp
            let conditionRootNode = specificRootNode == "" ? true : event.rootNode?.name == specificRootNode
        
            return conditionTime && conditionApp && conditionRootNode
		}

		let nodes = Dictionary(
			grouping: matchingEvents.map {
				return ($0.node, $0.rootNode, Double($0.energy))
			}
		) { (node, rootNode, energy: Double) in
			NodePresentation(node: node, rootNode: rootNode)
		}.mapValues {
			$0.map(\.2).reduce(0, +)
		}

		let totalEnergy = nodes.values.reduce(0, +)
        let pasteBoard = NSPasteboard.general
		let sortedNodes = nodes.sorted {
			$0.value > $1.value
		}.map(\.key)

		// Seems broken, so comment it out for now.
		//		Table(sortedNodes, selection: $selectedNodes) {
		//			TableColumn("") { node in
		List {
			Section(
				content: {
					ForEach(sortedNodes) { node in
						HStack {
							VStack(alignment: .leading) {
								Text("\(node.node?.name ?? "<Unknown>")")
									.font(Font.title3)
                                    .onTapGesture {
                                        pasteBoard.clearContents()
                                        pasteBoard.setString(node.node?.name ?? "", forType: .string)
                                        copiedContent = node.node?.name ?? ""
                                        self.showsAlert = true
                                    }.alert(isPresented: self.$showsAlert) {
                                        Alert(title: Text("\(copiedContent) copied"))
                                    }
								Text("\(node.rootNode?.name ?? "<Unknown>")")
									.foregroundColor(.secondary)
                                    .onTapGesture {
                                        pasteBoard.clearContents()
                                        pasteBoard.setString(node.rootNode?.name ?? "", forType: .string)
                                        copiedContent = node.rootNode?.name ?? ""
                                        self.showsAlert = true
                                    }.alert(isPresented: self.$showsAlert) {
                                        Alert(title: Text("\(copiedContent) copied"))
                                    }
							}
							Spacer()
							Text(String(format: "%.02f%%", nodes[node]! / totalEnergy * 100))
								.font(.title2)
						}
					}
				},
				header: {
					HStack(spacing: 0) {
						Image(systemName: "clock")
						Text("\(Date(timeIntervalSince1970: selectedRange.lowerBound), formatter: Self.dateFormatter) - \(Date(timeIntervalSince1970: selectedRange.upperBound), formatter: Self.dateFormatter)")
							.font(.body.monospacedDigit())
						Spacer()
						Image(systemName: "sum")
						Text(String(format: "%.02f Wh", totalEnergy / 1_000_000))
							.font(.body.monospacedDigit())
						Spacer()
					}
				}
			)
			.collapsible(false)
		}
		//		}
	}
}

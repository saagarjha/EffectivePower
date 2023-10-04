//
//  UsageView.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/23/22.
//

import SwiftUI

struct NodeView: View {
	let node: CompleteNode
	let energy: Double
	let totalEnergy: Double

	var body: some View {
		HStack {
			VStack(alignment: .leading) {
				Text("\(node.node?.name ?? "<Unknown>")")
					.font(Font.title3)
				Text("\(node.rootNode?.name ?? "<Unknown>")")
					.foregroundColor(.secondary)
			}
			Spacer()
			Text(String(format: "%.02f%%", energy / totalEnergy * 100))
				.font(.title2)
		}
	}
}

struct UsageView: View {
	let events: [Event]
	@Binding
	var selectedRange: ClosedRange<TimeInterval>?
	@Binding
	var selectedNodes: Set<CompleteNode.ID>
	@State
	var filter: String = ""

	static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		if #available(macOS 14.0, *) {
			dateFormatter.dateStyle = .short
		} else {
			dateFormatter.dateStyle = .none
		}
		dateFormatter.timeStyle = .medium
		return dateFormatter
	}()

	var body: some View {
		let selectedRange = selectedRange ?? Date.distantPast.timeIntervalSince1970...Date.distantFuture.timeIntervalSince1970
		let matchingEvents = events.filter { event in
			let start = max(event.timestamp.lowerBound.timeIntervalSince1970, selectedRange.lowerBound)
			let end = min(event.timestamp.upperBound.timeIntervalSince1970, selectedRange.upperBound)
			return start < end
		}

		let nodes = Dictionary(
			grouping: matchingEvents.map {
				return ($0.node, $0.rootNode, Double($0.energy))
			}
		) { (node, rootNode, energy: Double) in
			CompleteNode(node: node, rootNode: rootNode)
		}.mapValues {
			$0.map(\.2).reduce(0, +)
		}

		let totalEnergy = nodes.values.reduce(0, +)

		let sortedNodes = nodes.sorted {
			$0.key.id > $1.key.id
		}.sorted {
			$0.value > $1.value
		}
		.map(\.key)
		.filter {
			return filter.isEmpty || ($0.node?.name.localizedCaseInsensitiveContains(filter) ?? false) || ($0.rootNode?.name.localizedCaseInsensitiveContains(filter) ?? false)
		}

		if #available(macOS 14.0, *) {
			Table(sortedNodes, selection: $selectedNodes) {
				TableColumn("\(Self.dateFormatter.string(from: Date(timeIntervalSince1970: selectedRange.lowerBound))) - \(Self.dateFormatter.string(from: Date(timeIntervalSince1970: selectedRange.upperBound)))") { node in
					NodeView(node: node, energy: nodes[node]!, totalEnergy: totalEnergy)
						.padding([.leading, .trailing])
				}
			}
			.searchable(text: $filter)
			.alternatingRowBackgrounds(.disabled)
			.scrollContentBackground(.hidden)
			.safeAreaInset(edge: .bottom, spacing: 0) {
				HStack(spacing: 0) {
					Group {
						Text(String(format: "%.02f Wh", totalEnergy / 1_000_000))
							.padding([.leading], 20)
						if !selectedNodes.isEmpty {
							let visibleIDs = Set(sortedNodes.map(\.id))
							let selection = nodes.filter {
								selectedNodes.contains($0.key.id) && visibleIDs.contains($0.key.id)
							}
							let selectedEnergy = selection.values.reduce(0, +)
							Text(String(format: "(%.02f Wh, %.02f%%)", selectedEnergy / 1_000_000, selectedEnergy / totalEnergy * 100))
						}
					}
					.font(.body.monospacedDigit())
					.padding(4)
					Spacer()
				}
				.background(Material.bar)
			}
			.toolbar {
				Spacer()
			}
		} else {
			let list = List {
				Section(
					content: {
						ForEach(sortedNodes) { node in
							NodeView(node: node, energy: nodes[node]!, totalEnergy: totalEnergy)
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
			.listStyle(.sidebar)
			if #available(macOS 12.0, *) {
				list.searchable(text: $filter)
			} else {
				list
			}
		}
	}
}

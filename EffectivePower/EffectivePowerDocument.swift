//
//  EffectivePowerDocument.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/8/22.
//

import SwiftUI
import UniformTypeIdentifiers

extension UTType {
	static var plsql = Self(importedAs: "com.saagarjha.plsql")
}

struct Node: Hashable, Identifiable {
	let name: String

	var id: String {
		name
	}
}

struct CompleteNode: Hashable, Identifiable {
	let node: Node?
	let rootNode: Node?

	var id: String {
		(node?.id ?? "") + " " + (rootNode?.id ?? "")
	}
}

class Event: Identifiable {
	let node: Node?
	let rootNode: Node?
	weak var parent: Event?
	let timestamp: ClosedRange<Date>
	var energy: Int

	var children = [Event]()
	
	var completeNode: CompleteNode {
		CompleteNode(node: node, rootNode: rootNode)
	}

	init(node: Node?, rootNode: Node?, parent: Event?, timestamp: ClosedRange<Date>, energy: Int) {
		self.node = node
		self.rootNode = rootNode
		self.parent = parent
		self.timestamp = timestamp
		self.energy = energy
	}
}

class BatteryStatus: Hashable, Identifiable {
	let timestamp: Date
	let level: Double
	let charging: Bool

	init(timestamp: Date, level: Double, charging: Bool) {
		self.timestamp = timestamp
		self.level = level
		self.charging = charging
	}

	static func == (lhs: BatteryStatus, rhs: BatteryStatus) -> Bool {
		ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(ObjectIdentifier(self))
	}
}

class EffectivePowerDocument: FileDocument, Equatable {
	static var readableContentTypes: [UTType] { [.plsql] }

	let nodes: [Int: Node]
	let events: [Event]
	let batteryStatuses: [BatteryStatus]

	let bounds: ClosedRange<Date>

	let deviceName: String?
	let deviceModel: String?
	let deviceBuild: String?

	init() {
		nodes = [:]
		events = []
		batteryStatuses = []
		deviceName = ""
		deviceModel = ""
		deviceBuild = ""
		bounds = Date()...(Date())
	}

	required init(configuration: ReadConfiguration) throws {
		let database = try SQLiteDatabase(data: configuration.file.regularFileContents!)
		var nodes = [Int: Node]()
		for row in try database.execute(statement: "SELECT ID, Name FROM 'PLAccountingOperator_EventNone_Nodes'") {
			let row = row.map {
				$0!
			}
			nodes[Int(row[0])!] = Node(name: row[1])
		}
		self.nodes = nodes
		
		var offsets = [(Double, Double)]()
		for row in try database.execute(statement: "SELECT timestamp, system FROM PLStorageOperator_EventForward_TimeOffset") {
			let row = row.map {
				$0!
			}
			let timestamp = Double(row[0])!
			let offset = Double(row[1])!
			offsets.append((timestamp, offset))
		}
		offsets.sort {
			$0.0 < $1.0
		}
		
		func offset(for timestamp: Double) -> Double {
			offsets[offsets.index(offsets.firstIndex {
				$0.0 > timestamp
			} ?? offsets.endIndex, offsetBy: -1, limitedBy: offsets.startIndex) ?? offsets.startIndex].1
		}

		var events = [Int: Event]()
		for row in try database.execute(statement: "SELECT ID, NodeID, RootNodeID, ParentEntryID, timestamp, StartOffset, EndOffset, Energy, CorrectionEnergy FROM 'PLAccountingOperator_EventInterval_EnergyEstimateEvents'") {
			let row = row.map {
				$0!
			}
			let timestamp = Double(row[4])!
			let offset = offset(for: timestamp)
			let startOffset = Double(row[5])!
			let endOffset = Double(row[6])!
			let _start = Date(timeIntervalSince1970: timestamp + startOffset / 1_000)
			let _end = Date(timeIntervalSince1970: timestamp + endOffset / 1_000)
			// Ignore these, as per Apple's response to FB11722856:
			// These are the “dummy’ power events…created with a startDate of NSDate distantPast
			guard abs(_start.timeIntervalSince(.distantPast)) >= 1,
				  abs(_end.timeIntervalSince(.distantPast)) >= 1 else {
				print("Ignoring dummy events: ", _start, _end)
				continue
			}
			let start = _start.addingTimeInterval(offset)
			let end = _end.addingTimeInterval(offset)
			if start == end {
				continue
			}
			let parent = events[Int(row[3])!]
			let energy = Int(row[7])! + Int(row[8])!
			guard energy > 0 else {
				continue
			}
			let event = Event(node: nodes[Int(row[1])!], rootNode: nodes[Int(row[2])!], parent: parent, timestamp: start...end, energy: energy)
			parent?.children.append(event)
			events[Int(row[0])!] = event
		}
		self.events = Array(events.values)

		var roots = self.events.filter {
			$0.parent == nil
		}

		while let event = roots.popLast() {
			event.energy -= event.children.map(\.energy).reduce(0, +)
			roots.append(contentsOf: event.children)
		}

		var batteryStatus = [BatteryStatus]()
		for row in try database.execute(statement: "SELECT timestamp, Level, ExternalConnected FROM 'PLBatteryAgent_EventBackward_Battery'") {
			let row = row.map {
				$0!
			}
			let timestamp = Double(row[0])!
			let offset = offset(for: timestamp)
			batteryStatus.append(BatteryStatus(timestamp: Date(timeIntervalSince1970: timestamp + offset), level: Double(row[1])!, charging: Int(row[2])! != 0))
		}
		self.batteryStatuses = batteryStatus.sorted {
			$0.timestamp < $1.timestamp
		}

		let configuration = try database.execute(statement: "SELECT timestamp, DeviceName, Device, Build FROM 'PLConfigAgent_EventNone_Config' ORDER BY timestamp")
		deviceName =
			configuration.compactMap {
				$0[1]
			}.last
		deviceModel =
			configuration.compactMap {
				$0[2]
			}.last
		deviceBuild =
			configuration.compactMap {
				$0[3]
			}.last

		bounds = min(batteryStatuses.first!.timestamp, self.events.map(\.timestamp.lowerBound).min()!)...max(batteryStatuses.last!.timestamp, self.events.map(\.timestamp.upperBound).max()!)
	}

	func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
		configuration.existingFile!
	}

	static func == (lhs: EffectivePowerDocument, rhs: EffectivePowerDocument) -> Bool {
		return lhs === rhs
	}
}

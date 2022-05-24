//
//  SQLiteDatabase.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/23/22.
//

import Foundation
import SQLite3

class SQLiteDatabase {
	struct Error: Swift.Error {
		var error: CInt

		static func check(_ error: CInt) throws {
			guard error == SQLITE_OK else {
				throw Self(error: error)
			}
		}
	}

	var connection: OpaquePointer?

	init(data: Data) throws {
		try Error.check(sqlite3_open_v2(":memory:", &connection, SQLITE_OPEN_READONLY, nil))
		var data = data
		try data.withUnsafeMutableBytes { buffer in
			try Error.check(sqlite3_deserialize(connection, nil, buffer.baseAddress!.bindMemory(to: CChar.self, capacity: buffer.count), sqlite3_int64(buffer.count), sqlite3_int64(buffer.count), UInt32(SQLITE_DESERIALIZE_READONLY)))
		}
	}

	deinit {
		precondition(sqlite3_close_v2(connection) == SQLITE_OK)
	}

	func execute(statement: String) throws -> [[String?]] {
		var results = [[String?]]()
		var update: (([String?]) -> Void) = { row in
			results.append(row)
		}
		try withUnsafePointer(to: &update) { update in
			try Error.check(
				sqlite3_exec(
					connection, statement,
					{ context, columns, values, _ in
						let update = context!.assumingMemoryBound(to: (([String?]) -> Void).self)
						let values = UnsafeBufferPointer(start: values!, count: Int(columns))
						update.pointee(
							values.map {
								$0.flatMap {
									String(cString: $0)
								}
							})
						return 0
					}, UnsafeMutableRawPointer(mutating: update), nil))
		}
		return results
	}
}

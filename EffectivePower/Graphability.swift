//
//  Graphability.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/23/22.
//

extension BatteryStatus: BinaryGraphable {
	@_implements(BinaryGraphable,value)
	var BooleanGraphable_value: Bool {
		charging
	}

	@_implements(BinaryGraphable,position)
	var BooleanGraphable_position: Double {
		timestamp.timeIntervalSince1970
	}
}

extension BatteryStatus: LinearGraphable {
	@_implements(LinearGraphable,value)
	var LinearGraphable_value: Double {
		level
	}

	@_implements(LinearGraphable,position)
	var LinearGraphable_position: Double {
		timestamp.timeIntervalSince1970
	}
}

extension Event: HistogramGraphable {
	var value: Double {
		Double(energy)
	}

	var position: ClosedRange<Double> {
		timestamp.lowerBound.timeIntervalSince1970...timestamp.upperBound.timeIntervalSince1970
	}
}

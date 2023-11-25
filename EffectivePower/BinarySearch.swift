//
//  BinarySearch.swift
//  EffectivePower
//
//  Created by Saagar Jha on 11/23/23.
//

extension RandomAccessCollection {
	func lowerBound<T>(of value: T, transform: (Element) -> T, comparator: (T, T) -> Bool) -> Index {
		guard !isEmpty else {
			return startIndex
		}

		let test = index(startIndex, offsetBy: distance(from: startIndex, to: endIndex) / 2)
		if comparator(transform(self[test]), value) {
			return self[index(after: test)...].lowerBound(of: value, transform: transform, comparator: comparator)
		} else {
			return self[..<test].lowerBound(of: value, transform: transform, comparator: comparator)
		}
	}

	func lowerBound(of value: Element, comparator: (Element, Element) -> Bool) -> Index {
		lowerBound(of: value, transform: { $0 }, comparator: comparator)
	}

	func lowerBound<T: Comparable>(of value: T, transform: (Element) -> T) -> Index {
		lowerBound(of: value, transform: transform, comparator: <)
	}

	func upperBound<T>(of value: T, transform: (Element) -> T, comparator: (T, T) -> Bool) -> Index {
		guard !isEmpty else {
			return startIndex
		}

		let test = index(startIndex, offsetBy: distance(from: startIndex, to: endIndex) / 2)
		if comparator(value, transform(self[test])) {
			return self[..<test].upperBound(of: value, transform: transform, comparator: comparator)
		} else {
			return self[index(after: test)...].upperBound(of: value, transform: transform, comparator: comparator)
		}
	}

	func upperBound(of value: Element, comparator: (Element, Element) -> Bool) -> Index {
		upperBound(of: value, transform: { $0 }, comparator: comparator)
	}

	func upperBound<T: Comparable>(of value: T, transform: (Element) -> T) -> Index {
		upperBound(of: value, transform: transform, comparator: <)
	}
}

extension RandomAccessCollection where Element: Comparable {
	func lowerBound(of value: Element) -> Index {
		lowerBound(of: value, comparator: <)
	}

	func upperBound(of value: Element) -> Index {
		upperBound(of: value, comparator: <)
	}
}

//
//  Polyfills.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/24/22.
//

import SwiftUI

extension Color {
	static var foregroundish: Self {
		if #available(macOS 12.0, *) {
			return Color(nsColor: .textColor)
		} else {
			switch NSApp.effectiveAppearance.name {
				case .aqua:
					return .black
				case .darkAqua:
					return .white
				default:
					fatalError()
			}
		}
	}

	static var backgroundish: Self {
		if #available(macOS 12.0, *) {
			return Color(nsColor: .textBackgroundColor)
		} else {
			switch NSApp.effectiveAppearance.name {
				case .aqua:
					return .white
				case .darkAqua:
					return .black
				default:
					fatalError()
			}
		}
	}
}

extension View {
	@ViewBuilder
	func materialBackground() -> some View {
		if #available(macOS 12.0, *) {
			background(Material.regular)
		} else {
			background(Color.backgroundish)
		}
	}
}

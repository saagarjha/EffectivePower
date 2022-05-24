//
//  MouseTrackingView.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/23/22.
//

import SwiftUI

struct MouseTrackingView: NSViewRepresentable {
	class NSViewType: NSView {
		@Binding
		var location: CGPoint?

		init(location: Binding<CGPoint?>) {
			self._location = location
			super.init(frame: .zero)
			addTrackingArea(NSTrackingArea(rect: self.bounds, options: [.mouseMoved, .mouseEnteredAndExited, .enabledDuringMouseDrag, .inVisibleRect, .activeInKeyWindow], owner: self, userInfo: nil))
		}

		required init?(coder: NSCoder) {
			fatalError()
		}

		override func mouseExited(with event: NSEvent) {
			super.mouseExited(with: event)
			location = nil
		}

		override func mouseMoved(with event: NSEvent) {
			super.mouseMoved(with: event)
			location = convert(event.locationInWindow, from: nil)
		}
	}

	@Binding
	var location: CGPoint?

	func makeNSView(context: Context) -> NSViewType {
		.init(location: $location)
	}

	func updateNSView(_ nsView: NSViewType, context: Context) {
	}
}

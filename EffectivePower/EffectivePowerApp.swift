//
//  EffectivePowerApp.swift
//  EffectivePower
//
//  Created by Saagar Jha on 5/8/22.
//

import SwiftUI

@main
struct EffectivePowerApp: App {
	var body: some Scene {
		DocumentGroup(newDocument: EffectivePowerDocument()) { file in
            ContentView(document: file.$document, specificApp: "", specificRootNode: "")
		}
	}
}

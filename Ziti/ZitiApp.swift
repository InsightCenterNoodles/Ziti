//
//  ZitiApp.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/12/24.
//

import SwiftUI

@main
struct ZitiApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }.windowStyle(.volumetric)

        ImmersiveSpace(id: "ImmersiveSpace") {
            ImmersiveView()
        }
    }
}

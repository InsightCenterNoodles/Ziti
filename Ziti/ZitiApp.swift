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
        }.windowStyle(.volumetric).defaultSize(width: 2, height: 1, depth: 2, in: .meters)

//        ImmersiveSpace(id: "ImmersiveSpace") {
//            ImmersiveView()
//        }
    }
}

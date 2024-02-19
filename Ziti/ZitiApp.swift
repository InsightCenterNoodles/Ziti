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
        WindowGroup("NOODLES Client") {
            CommandView()
                .frame(minWidth: 100, maxWidth: 400, minHeight: 100, maxHeight: 100)
        }.windowResizability(.contentSize)
        
        WindowGroup(id: "noodles_content_window", for: NewNoodles.self) {
            $nn in
            ContentView(new_noodles_config: nn)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 2, height: 1, depth: 2, in: .meters)

//        ImmersiveSpace(id: "ImmersiveSpace") {
//            ImmersiveView()
//        }
    }
}

struct NewNoodles : Decodable, Encodable, Hashable {
    var id = UUID()
    let hostname: String
}

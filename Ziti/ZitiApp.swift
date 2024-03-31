//
//  ZitiApp.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/12/24.
//

import SwiftUI

@main
struct ZitiApp: App {
    @State private var current_style: ImmersionStyle = .mixed
    
    var body: some Scene {
        WindowGroup("NOODLES Client") {
            CommandView()
                .frame(minWidth: 100, minHeight: 100)
        }.windowResizability(.automatic)
        
        WindowGroup(id: "noodles_content_window", for: NewNoodles.self) {
            $nn in
            ContentView(new: nn!)
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1, height: 1, depth: 1, in: .meters)

        ImmersiveSpace(id: "noodles_immersive_space", for: NewNoodles.self) {
            $nn in
            NooImmersiveView(new: nn!)
        }.immersionStyle(selection: $current_style, in: .mixed)
    }
}

struct NewNoodles : Decodable, Encodable, Hashable {
    var id = UUID()
    let hostname: String
}

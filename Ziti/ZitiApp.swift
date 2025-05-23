//
//  ZitiApp.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/12/24.
//

import SwiftUI
import ZitiCore


@main
struct ZitiApp: App {
    @State private var current_style: ImmersionStyle = .mixed
    
    init() {
        initialize_ziti_core()
    }
    
    var body: some Scene {
        WindowGroup("Ziti Client", id: "noodles_browser") {
            BrowserView().frame(maxWidth: 500)
                //.frame(minWidth: 100, maxWidth: 450, minHeight: 100, maxHeight: 450)
        }.windowResizability(.contentSize)
        
        WindowGroup(id: "noodles_content_window_small", for: NewNoodles.self) {
            $nn in
            // we create new identifiers here to force each new open window to start in fresh state
            let new_nn = NewNoodles(hostname: nn?.hostname ?? "localhost")
            WindowView(new: new_nn, scale: .init(x: 0.5, y: 0.375, z: 0.5))
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 0.5, height: 0.375, depth: 0.5, in: .meters)
        
        WindowGroup(id: "noodles_content_window", for: NewNoodles.self) {
            $nn in
            let new_nn = NewNoodles(hostname: nn?.hostname ?? "localhost")
            WindowView(new: new_nn, scale: .init(x: 1.0, y: 0.75, z: 1.0))
        }
        .windowStyle(.volumetric)
        .defaultSize(width: 1, height: 0.75, depth: 1, in: .meters)

        ImmersiveSpace(id: "noodles_immersive_space", for: NewNoodles.self) {
            $nn in
            let new_nn = NewNoodles(hostname: nn?.hostname ?? "localhost")
            NooImmersiveView(new: new_nn)
        }.immersionStyle(selection: $current_style, in: .mixed)
    }
}

struct NewNoodles : Decodable, Encodable, Hashable {
    var id = UUID()
    let hostname: String
}

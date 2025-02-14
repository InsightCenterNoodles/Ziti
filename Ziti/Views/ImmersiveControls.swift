//
//  ImmersiveControls.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/10/25.
//

import SwiftUI
import ZitiCore

struct ImmersiveControls : View {
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    @Binding var communicator: NoodlesCommunicator?
    
    var body: some View {
        VStack {
            CompactMethodView(communicator: $communicator)
            
            Button("Close") {
                Task {
                    print("Close immersive")
                    await dismissImmersiveSpace()
                }
            }
        }.frame(minWidth: 100, maxWidth: 150, minHeight: 100, maxHeight: 300).padding().glassBackgroundEffect()
    }
}


//#Preview(windowStyle: .volumetric) {
//    ContentView(NewNoodles(hostname: ""))
//}


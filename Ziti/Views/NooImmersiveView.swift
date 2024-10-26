//
//  ContentView.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/29/24.
//

import SwiftUI
import RealityKit
import RealityKitContent


struct NooImmersiveView: View {
    var new_noodles_config : NewNoodles!
    
    @State private var noodles_state : NoodlesCommunicator?
    @State private var noodles_world : NoodlesWorld?
    @State private var is_bad_host = false
    
    @State private var global_scale = 1.0
    @State private var auto_extent = false
    
    @State private var current_scene : RealityViewContent!
    @State private var current_doc_method_list = MethodListObservable()
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    init(new: NewNoodles) {
        new_noodles_config = new
    }
    
    var body: some View {
        RealityView { content, attachments in
            self.current_scene = content
            
            let u = URL(string: new_noodles_config.hostname) ?? URL(string: "ws://localhost:50000")!
            
            noodles_world = await NoodlesWorld(content, current_doc_method_list, initial_offset: simd_float3([0, 1, 0]))
            
            noodles_state = NoodlesCommunicator(url: u, world: noodles_world!)
            
            noodles_world?.comm = noodles_state
            
            let anchor = AnchorEntity(.hand(.left, location: .aboveHand), trackingMode: .predicted)
            anchor.name = "hand_anchor"
            
            content.add(anchor)
            
            if let att = attachments.entity(for: "hand_label") {
                att.components[BillboardComponent.self] = .init()
                anchor.addChild(att)
            }
            
        } attachments: {
            Attachment(id: "hand_label") {
                VStack {
                    Button("Close") {
                        Task {
                            print("Close window for \(new_noodles_config.hostname)")
                            await dismissImmersiveSpace()
                        }
                    }
                }.environment(current_doc_method_list).frame(minWidth: 100, maxWidth: 300, minHeight: 100, maxHeight: 300).padding().glassBackgroundEffect()
                
            }
        } .installGestures()
    }
    
    func frame_all() {
        auto_extent = true
        
        noodles_state?.world.frame_all(target_volume: SIMD3<Float>(2,1,2))
    }
}

//#Preview(windowStyle: .volumetric) {
//    ContentView(NewNoodles(hostname: ""))
//}

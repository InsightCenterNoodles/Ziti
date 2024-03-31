//
//  ContentView.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/12/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

struct ContentView: View {
    var new_noodles_config : NewNoodles
    
    @State private var noodles_state : NoodlesCommunicator?
    @State private var noodles_world : NoodlesWorld?
    @State private var is_bad_host = false
    
    @State private var global_scale = 1.0
    @State private var auto_extent = false
    
    @State private var current_scene : RealityViewContent!
    @State private var current_doc_method_list = MethodListObservable()
    @State private var angle = Angle(degrees: 0.0)
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    init(new: NewNoodles) {
        new_noodles_config = new
    }
    
    var body: some View {
        ZStack {
            VStack {
                Text("Current Host: \(new_noodles_config.hostname)")
                Text("Available methods")
                MethodListView()
                
            }.environment(current_doc_method_list).padding().glassBackgroundEffect()
            
            RealityView { content in
                self.current_scene = content
                
                let u = URL(string: new_noodles_config.hostname) ?? URL(string: "ws://localhost:50000")!
                
                noodles_world = NoodlesWorld(content, current_doc_method_list)
                
                noodles_state = NoodlesCommunicator(url: u, world: noodles_world!)
                
            } update: { content in
                
//                if !auto_extent{
//                    var fv = 1.0
//                    if global_scale > 0 {
//                        fv = global_scale
//                    } else if global_scale < 0 {
//                        fv = 1.0 / (-global_scale)
//                    }
//                    let scalar = Float(fv)
//                    let root = noodles_state!.world.root_entity
//                    var current_tf = root.transform
//                    current_tf.scale = [scalar, scalar, scalar]
//                    root.move(to: current_tf, relativeTo: root.parent, duration: 1)
//                }
            }.installGestures()
            
            VStack {
                HStack {
                    Button(action: frame_all) {
                        Text("Frame")
                    }
                    Button("Immersive") {
                        Task {
                            print("Open window for \(new_noodles_config.hostname)")
                            let nn = new_noodles_config
                            let result = await openImmersiveSpace(id: "noodles_immersive_space", value: nn)
                            
                            if case .error = result {
                                print("An error occurred")
                            }
                        }
                    }
                    
                    Button("No Immersive") {
                        Task {
                            print("Close window for \(new_noodles_config.hostname)")
                            await dismissImmersiveSpace()
                        }
                    }
                }
                CompactMethodView(communicator: $noodles_state)
                
            }.environment(current_doc_method_list).padding().frame(maxWidth: 450).glassBackgroundEffect().offset(y: 450)
        }
    }
    
    func frame_all() {
        auto_extent = true
        
        noodles_state?.world.frame_all(target_volume: SIMD3<Float>(1,1,1))
    }
}

//#Preview(windowStyle: .volumetric) {
//    ContentView(NewNoodles(hostname: ""))
//}

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
    
    @State private var auto_extent = false
    @State private var show_details = false
    @State private var allow_obj_interaction = false
    
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
            
            RealityView { content in
                self.current_scene = content
                
                let u = URL(string: new_noodles_config.hostname) ?? URL(string: "ws://localhost:50000")!
                
                noodles_world = NoodlesWorld(content, current_doc_method_list)
                
                noodles_state = NoodlesCommunicator(url: u, world: noodles_world!)
                
                noodles_world?.comm = noodles_state
                
            } update: { content in
                
            }.installGestures()
            
            VStack {
                
                if show_details {
                    VStack {
                        Text("Current Host: \(new_noodles_config.hostname)").font(.headline)
                        MethodListView()
                    }.frame(maxHeight: 400)
                    Divider()
                }
                
                HStack {
                    Button(action: frame_all) {
                        Label("Frame", systemImage: "arrow.up.backward.and.arrow.down.forward.square.fill")
                    }
                    Button(action: {
                        Task {
                            print("Open window for \(new_noodles_config.hostname)")
                            let nn = new_noodles_config
                            let result = await openImmersiveSpace(id: "noodles_immersive_space", value: nn)
                            
                            if case .error = result {
                                print("An error occurred")
                            }
                        }
                    }) {
                        Label("Enter immersive mode", systemImage: "globe").labelStyle(.iconOnly)
                    }
                    Toggle(isOn: $allow_obj_interaction) {
                        Label("Object Interaction", systemImage: "squareshape.controlhandles.on.squareshape.controlhandles").labelStyle(.iconOnly)
                    }.toggleStyle(.button).onChange(of: allow_obj_interaction, initial: false) {
                        _, new_value in
                        noodles_world?.set_all_entity_input(enabled: new_value)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            show_details.toggle()
                        }
                    }) {
                        Label(show_details ? "Hide Details" : "Show Details" , systemImage: "slider.horizontal.3").labelStyle(.iconOnly)
                    }
                }
                CompactMethodView(communicator: $noodles_state)
                
            }.environment(current_doc_method_list)
                .padding()
                .frame(maxWidth: show_details ? 500 : 450)
                .glassBackgroundEffect()
                .offset(y: show_details ? 300 : 475)
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

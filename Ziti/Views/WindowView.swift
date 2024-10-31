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

struct WindowView: View {
    var new_noodles_config : NewNoodles
    var initial_scale: SIMD3<Float>
    
    @State private var noodles_state : NoodlesCommunicator?
    @State private var noodles_world : NoodlesWorld?
    @State private var is_bad_host = false
    
    @State private var auto_extent = false
    @State private var show_details = false
    
    @State private var current_scene : RealityViewContent!
    @State private var current_doc_method_list = MethodListObservable()
    
    @State private var particle_speed: Double = GlobalAdvectionSettings.shared.advection_speed
    
    @State private var show_info_window = false
    @StateObject private var info_model = ControlInfoModel()
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    init(new: NewNoodles, scale: SIMD3<Float>) {
        new_noodles_config = new
        initial_scale = scale
    }
    
    var body: some View {
        RealityView.init(make: { content in
            self.current_scene = content
            
            let u = URL(string: new_noodles_config.hostname) ?? URL(string: "ws://localhost:50000")!
            
            noodles_world = await NoodlesWorld(content, current_doc_method_list)
            
            noodles_state = NoodlesCommunicator(url: u, world: noodles_world!)
            
            noodles_world?.comm = noodles_state
            
        }).installGestures().ornament(attachmentAnchor: .scene(.bottomFront), ornament: {
            VStack {
                HStack {
                    Button(action: {
                        if let current_index = ControlInteractionMode.allCases.firstIndex(of: info_model.interaction) {
                            let nextIndex = (current_index + 1) % ControlInteractionMode.allCases.count
                            info_model.interaction = ControlInteractionMode.allCases[nextIndex]
                        }
                    }) {
                        Label(info_model.text_for_current_option(), systemImage: info_model.icon_for_current_option() )
                    }
                    
                    CompactMethodView(communicator: $noodles_state)
                }
                
            }.padding().glassBackgroundEffect()
        }).ornament(attachmentAnchor: .scene(.back), ornament: {
            if show_info_window {
                ControlView(info_model: info_model)
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .transition(.opacity)
            }
        }).ornament(attachmentAnchor: .scene(.trailingFront), ornament: {
            VStack {
                Button(action: frame_all) {
                    Label("Frame", systemImage: "arrow.up.backward.and.arrow.down.forward.square.fill").labelStyle(.iconOnly)
                }
                Divider()
                Button(action: {
                    Task {
                        print("Open window for \(new_noodles_config.hostname)")
                        let nn = new_noodles_config
                        let result = await openImmersiveSpace(id: "noodles_immersive_space", value: nn)
                        
                        if case .error = result {
                            print("An error occurred")
                        }
                    }
                    
                    dismiss()
                }) {
                    Label("Immersive Mode", systemImage: "sharedwithyou.circle.fill").labelStyle(.iconOnly)
                }
                Button(action: {
                    openWindow(id: "noodles_browser")
                }) {
                    Label("New Connection", systemImage: "note.text.badge.plus").labelStyle(.iconOnly)
                }
                Divider()
                Button( action: {
                    withAnimation {
                        if (show_info_window) {
                            show_info_window = false
                        } else {
                            show_info_window = true
                        }
                    }
                }) {
                    Label("Info", systemImage: "info.circle.fill").labelStyle(.iconOnly)
                }
            }
        }).environment(current_doc_method_list)
            .onAppear() { show_info_window = false }.onDisappear {
                reset()
            }.onChange(of: info_model.interaction) {
                var root_visible = false
                
                switch info_model.interaction {
                case .none:
                    noodles_world?.set_all_entity_input(enabled: false)
                case .root:
                    noodles_world?.set_all_entity_input(enabled: false)
                    root_visible = true
                case .item:
                    noodles_world?.set_all_entity_input(enabled: true)
                }
                
                noodles_world?.root_controller.isEnabled = root_visible
            }
        
    }
    
    func reset() {
        guard let n = noodles_world else {
            return
        }
        n.clear()
    }
    
    func frame_all() {
        auto_extent = true
        
        noodles_state?.world.frame_all(target_volume: initial_scale)
    }
    
    func debug() {
        //instance_test.update()
        
        //        let buff = CPUInstanceBuffer(instance_count: 10)
        //
        //        buff.test_fill()
        //
        //        buff.update()
        //
        //        let bounds = BoundingBox(min: SIMD3<Float>(-4.0, -4.0, -4.0), max: SIMD3<Float>(4.0, 4.0, 4.0))
        //
        //        noodles_world?.instance_test.update(instance_buffer: buff.instance_buffer, bounds: bounds)
    }
}

//#Preview(windowStyle: .volumetric) {
//    ContentView(NewNoodles(hostname: ""))
//}

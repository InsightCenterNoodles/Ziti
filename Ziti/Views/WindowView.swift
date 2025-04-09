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

import ZitiCore

struct WindowView: View {
    var new_noodles_config : NewNoodles
    var initial_scale: SIMD3<Float>
    
    @State private var noodles_state : NoodlesCommunicator?
    @State private var noodles_world : NoodlesWorld?
    @State private var is_bad_host = false
    
    @State private var auto_extent = false
    @State private var show_details = false
    
    @State private var current_scene : (any RealityViewContentProtocol)!
    @State private var current_root: Entity!
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
            
            current_root = Entity()
            
            content.add(current_root)
            
            dump(new_noodles_config.hostname)
            dump(URL(string: new_noodles_config.hostname))
            
            let u = URL(string: new_noodles_config.hostname) ?? URL(string: "ws://localhost:50000")!
            
            let error_entity = try! await Entity(named: "NoConnection", in: realityKitContentBundle)
            content.add(error_entity)
            
            noodles_world = await NoodlesWorld(
                current_root,
                error_entity,
                current_doc_method_list
            )
            
            noodles_state = NoodlesCommunicator(url: u, world: noodles_world!)
            
            noodles_world?.comm = noodles_state
            
        }).installGestures().ornament(attachmentAnchor: .scene(.bottomFront), ornament: {
            VStack {
                HStack {
                    Button(action: {
                        info_model.root_interaction_allowed.toggle()
                    }) {
                        Label("Change Root", systemImage: "scope").labelStyle(.iconOnly)
                    }.buttonStyle(.borderless)
                    
                    Button(action: {
                        info_model.item_interaction_allowed.toggle()
                    }) {
                        Label("Lock Items", systemImage: info_model.item_interaction_allowed ? "pencil" : "lock.document.fill").labelStyle(.iconOnly)
                    }.buttonStyle(.borderless)
                    
                    CompactMethodView(communicator: $noodles_state)
                }
                
            }.padding().glassBackgroundEffect()
        }).ornament(attachmentAnchor: .scene(.back), ornament: {
            if show_info_window {
                HStack {
                    ControlView(info_model: info_model,communicator: $noodles_state).padding()
                }.frame(minWidth: 400, minHeight: 400)
                    .glassBackgroundEffect().environment(current_doc_method_list)
                    .transition(.opacity)
            }
        }).ornament(attachmentAnchor: .scene(.trailingFront), ornament: {
            VStack {
                Button(action: frame_all) {
                    Label("Frame", systemImage: "arrow.up.backward.and.arrow.down.forward.square.fill").labelStyle(.iconOnly)
                }.buttonStyle(.borderless)
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
                }.buttonStyle(.borderless)
                Button(action: {
                    openWindow(id: "noodles_browser")
                }) {
                    Label("New Connection", systemImage: "note.text.badge.plus").labelStyle(.iconOnly)
                }.buttonStyle(.borderless)
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
                }.buttonStyle(.borderless)
            }.padding().glassBackgroundEffect()
        })
        .environment(current_doc_method_list)
        .onAppear() { show_info_window = false }.onDisappear {
            reset()
        }.onChange(of: info_model.root_interaction_allowed) {
            // Set the root controller visibility
            noodles_world?.root_controller.isEnabled = info_model.root_interaction_allowed
        }.onChange(of: info_model.item_interaction_allowed) {
            // Set all item visibility
            noodles_world?.set_all_entity_input(enabled: info_model.item_interaction_allowed)
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

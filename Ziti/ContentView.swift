//
//  ContentView.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/12/24.
//

import SwiftUI
import RealityKit
import RealityKitContent

import Starscream

struct ContentView: View {
    var new_noodles_config : NewNoodles!
    
    @State private var noodles_state : NoodlesCommunicator?
    @State private var is_bad_host = false
    
    @State private var global_scale = 1.0
    @State private var auto_extent = false
    
    @State private var current_scene : RealityViewContent?
    
    var body: some View {
        ZStack {
            RealityView { content in
                self.current_scene = content
                print("Starting connection to \(new_noodles_config.hostname)")
                
                if let u = URL(string: new_noodles_config.hostname) {
                    noodles_state = NoodlesCommunicator(url: u, scene: current_scene!)
                    is_bad_host = false
                } else {
                    is_bad_host = true
                }
                
            } update: { content in
                
                if !auto_extent{
                    if let state = noodles_state {
                        var fv = 1.0
                        if global_scale > 0 {
                            fv = global_scale
                        } else if global_scale < 0 {
                            fv = 1.0 / (-global_scale)
                        }
                        print("SCALING TO \(fv)")
                        let scalar = Float(fv)
                        let root = state.world.root_entity
                        var current_tf = root.transform
                        current_tf.scale = [scalar, scalar, scalar]
                        root.move(to: current_tf, relativeTo: root.parent, duration: 1)
                    }
                }
            } //.gesture(magnification)
            
            VStack {
                Text("Current Host: \(new_noodles_config.hostname)")
                Slider(value: $global_scale,
                       in: -1000 ... 1000,
                       onEditingChanged: { v in
                    auto_extent = false
                }) {
                    Text("Scale")
                }
                Text("Current Scale: \(global_scale)")
                Button(action: frame_all) {
                    Text("Frame")
                }
            }.frame(maxWidth: 360).padding().glassBackgroundEffect()
        }
    }
    
    func frame_all() {
        guard let state = noodles_state else {
            return
        }
        
        auto_extent = true
        
        let root = state.world.root_entity
        
        let bounds = root.visualBounds(recursive: true, relativeTo: nil)
        
        // ok has to be a better way to do this
        
        let target_box = SIMD3<Float>(2,1,2)
        
        let scales = target_box / bounds.extents
        
        let new_uniform_scale = scales.min()
        
        global_scale = Double(new_uniform_scale)
        
        var current_tf = root.transform
        
        current_tf.translation = -bounds.center * new_uniform_scale
        current_tf.scale = SIMD3<Float>(repeating: new_uniform_scale)
        
        root.move(to: current_tf, relativeTo: root.parent, duration: 2)
        
    }
}

//#Preview(windowStyle: .volumetric) {
//    ContentView(NewNoodles(hostname: ""))
//}

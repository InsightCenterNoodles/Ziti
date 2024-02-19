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
    
    @State private var global_scale = 1.0
    @State private var hostname = ""
    @State private var noodles_state : NoodlesCommunicator?
    @State private var is_bad_host = false
    
    @State private var current_scene : RealityViewContent?
    
    var body: some View {
        ZStack {
            RealityView { content in
                //let gen = MeshGeneration()
                
                //content.add(gen.build_simple_mesh())
                
                self.current_scene = content
                
                //noodles_state = NoodlesCommunicator(set_scene(scene: content)
            } update: { content in
                let scalar = Float(global_scale)
                noodles_state?.world.root_entity.transform.scale = [scalar, scalar, scalar]
            } //.gesture(magnification)
            
            VStack {
                HStack {
                    TextField("Address", text: $hostname).onSubmit {
                        do_connect()
                    }.disableAutocorrection(true)
                    Button(action: do_connect) {
                        Text("Go")
                    }.alert("Hostname is not valid", isPresented: $is_bad_host) {
                        Button("OK", role: .cancel) { }
                    }
                }
                Slider(value: $global_scale, in: 0.001 ... 1.0) {
                    Text("Scale")
                }
                Text("Current Scale: \(global_scale)")
            }.frame(width: 360).padding().glassBackgroundEffect()
        }.frame(alignment: .bottom)
    }
    
    func do_connect() {
        print("Connecting to \(hostname)")
        if let u = URL(string: hostname) {
            noodles_state = NoodlesCommunicator(url: u, scene: current_scene!)
            is_bad_host = false
        } else {
            is_bad_host = true
        }
        
    }
}

#Preview(windowStyle: .volumetric) {
    ContentView()
}

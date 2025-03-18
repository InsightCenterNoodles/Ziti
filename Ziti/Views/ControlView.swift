//
//  ControlView.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 10/18/24.
//

import SwiftUI

import ZitiCore

enum ControlInteractionMode: CaseIterable {
    case none
    case item
    case root
}

class ControlInfoModel: ObservableObject {
    @Published var title_text: String = "Connection Name"
    @Published var frame_all: Bool = false
    @Published var interaction: ControlInteractionMode = .none
    @Published var lock_scene_rotation: Bool = true
    @Published var lock_scene_scale: Bool = true
    @Published var scene_reconstruct: Bool = true
    
    func icon_for_current_option() -> String {
        switch interaction {
        case .none:
            return "pencil.slash"
        case .item:
            return "pencil"
        case .root:
            return "globe"
        }
    }
    
    func text_for_current_option() -> String {
        switch interaction {
        case .none:
            return "Static"
        case .item:
            return "Items"
        case .root:
            return "Root"
        }
    }
}


struct ControlView: View {
    @ObservedObject var info_model: ControlInfoModel
    
    @Binding var communicator: NoodlesCommunicator?
    
    var body: some View {
        MethodListView(communicator: $communicator)
    }
    
    func frame_all() {
        info_model.frame_all = !info_model.frame_all
    }
}

//if show_details {
//                    VStack {
//                        Text("Current Host: \(new_noodles_config.hostname)").font(.headline)
//                        MethodListView()
//                    }.frame(maxHeight: 400)
//                    Divider()
//                    Form {
//                        Section("Particles") {
//                            Slider(value: $particle_speed, in: 0...100, step: 0.0001)
//                                .padding()
//                                .onChange(of: particle_speed) {
//                                    GlobalAdvectionSettings.shared.advection_speed = particle_speed
//                                }
//                        }
//                    }
//                }

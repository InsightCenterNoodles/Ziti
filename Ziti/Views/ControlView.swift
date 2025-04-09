//
//  ControlView.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 10/18/24.
//

import SwiftUI

import ZitiCore


class ControlInfoModel: ObservableObject {
    @Published var title_text: String = "Connection Name"
    @Published var frame_all: Bool = false
    @Published var item_interaction_allowed = true
    @Published var root_interaction_allowed = false
    @Published var lock_scene_rotation: Bool = true
    @Published var lock_scene_scale: Bool = true
    @Published var scene_reconstruct: Bool = true
    
//    func icon_for_current_option() -> String {
//        switch interaction {
//        case .item:
//            return "pencil"
//        case .root:
//            return "globe"
//        }
//    }
//    
//    func text_for_current_option() -> String {
//        switch interaction {
//        case .item:
//            return "Items"
//        case .root:
//            return "Root"
//        }
//    }
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

//
//  MethodList.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 3/14/24.
//

import Foundation
import SwiftUI
import SwiftCBOR

struct MethodListView : View {
    @Environment(MethodListObservable.self) var current_doc_method_list
    
    @State var search_text = ""
    
    @State private var preferred_column =
    NavigationSplitViewColumn.sidebar
    
    var filtered_list : [AvailableMethod] {
        if search_text.isEmpty {
            return current_doc_method_list.available_methods
        } else {
            return current_doc_method_list.available_methods.filter {
                $0.method.info.name.lowercased().contains(search_text.lowercased())
            }
        }
    }
    
    var body: some View {
        TextField("Search", text: $search_text)
    }
}

struct InvokeMethodView : View {
    var method: AvailableMethod?
    
    var body: some View {
        VStack {
            Text("Invoke Method").font(.headline).padding()
            Text("Name: \(method?.method.info.name ?? "None" )")
        }
    }
}

struct CompactMethodView : View {
    @Environment(MethodListObservable.self) var current_doc_method_list
    
    @Binding var communicator: NoodlesCommunicator?
    
    var body: some View {
        if current_doc_method_list.has_any_time_methods() {
            HStack {
                if current_doc_method_list.has_step_time {
                    Button() {
                        start_invoke(CommonStrings.step_time, CBOR(-1), .Document)
                    } label: {
                        Label("Backward", systemImage: "backward.fill").labelStyle(.iconOnly)
                    }
                }
                
                if current_doc_method_list.has_time_animate {
                    Button() {
                        start_invoke(CommonStrings.animate_time, CBOR(0), .Document)
                    } label: {
                        Label("Stop", systemImage: "stop.fill").labelStyle(.iconOnly)
                    }
                }
                
                if current_doc_method_list.has_time_animate {
                    Button() {
                        start_invoke(CommonStrings.animate_time, CBOR(1), .Document)
                    } label: {
                        Label("Play", systemImage: "play.fill").labelStyle(.iconOnly)
                    }
                }
                
                if current_doc_method_list.has_step_time {
                    Button() {
                        start_invoke(CommonStrings.step_time, CBOR(1), .Document)
                    } label: {
                        Label("Forward", systemImage: "forward.fill").labelStyle(.iconOnly)
                    }
                }
            }.padding()
                .background(RoundedRectangle(cornerRadius: 15).fill(Color.gray.opacity(0.2)))
        }
    }
    
    func start_invoke(_ target_name: String, _ arg: CBOR, _ target: InvokeMessageOn) {
        guard let comm = communicator else {
            return
        }
        
        let maybe_m = current_doc_method_list.find_by_name(target_name);
        
        guard let m = maybe_m else {
            return
        }
        
        comm.invoke_method(method: m.method.info.id, context: target, args: [arg]) {
            reply in
            print("Message reply: ", reply);
        }
    }
}


struct AvailableMethod: Identifiable {
    var id = UUID()
    var method: NooMethod
    var context: NooID?
    var context_type: String
}

@Observable class MethodListObservable {
    var available_methods = [AvailableMethod]()
    var has_step_time = false
    var has_time_animate = false
    
    @MainActor
    func reset_list(_ l: [AvailableMethod]) {
        available_methods.removeAll()
        available_methods = l
        
        has_step_time = available_methods.contains(where: { $0.method.info.name == CommonStrings.step_time })
        has_time_animate = available_methods.contains(where: { $0.method.info.name == CommonStrings.step_time })
    }
    
    func has_any_time_methods() -> Bool {
        return has_step_time || has_time_animate
    }
    
    @MainActor
    func find_by_name(_ name: String) -> AvailableMethod? {
        return available_methods.first(where: { $0.method.info.name == name })
    }
}

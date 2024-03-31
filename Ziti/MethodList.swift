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
    
    @State var current_method: AvailableMethod?
    
    var body: some View {
        List(current_doc_method_list.list) { item in
            Button(action: {
                self.current_method = item
            }) {
                Text(item.method.info.name)
            }
        }.popover(item: $current_method) {
            item in InvokeMethodView(method: item)
        }
    }
}

struct InvokeMethodView : View {
    var method: AvailableMethod
    
    var body: some View {
        VStack {
            Text("Invoke Method").font(.headline).padding()
            Text("Name: \(method.method.info.name)")
        }
    }
}

struct CompactMethodView : View {
    @Environment(MethodListObservable.self) var current_doc_method_list
    
    @Binding var communicator: NoodlesCommunicator?
    
    var body: some View {
        HStack {
            if current_doc_method_list.list.contains(where: { $0.method.info.name == "noo::step_time" }) {
                Button() {
                    start_invoke("noo::step_time", CBOR(-1))
                } label: {
                    Label("Backward", systemImage: "backward.fill").labelStyle(.iconOnly)
                }
            }
            
            if current_doc_method_list.list.contains(where: { $0.method.info.name == "noo::animate_time" }) {
                Button() {
                    start_invoke("noo::animate_time", CBOR(1))
                } label: {
                    Label("Play", systemImage: "playpause.fill")
                }
            }
            
            if current_doc_method_list.list.contains(where: { $0.method.info.name == "noo::step_time" }) {
                Button() {
                    start_invoke("noo::step_time", CBOR(1))
                } label: {
                    Label("Forward", systemImage: "forward.fill").labelStyle(.iconOnly)
                }
            }
        }
    }
    
    func start_invoke(_ target_name: String, _ arg: CBOR) {
        guard let comm = communicator else {
            return
        }
        
        let maybe_m = current_doc_method_list.list.first(where: { $0.method.info.name == target_name });
        
        guard let m = maybe_m else {
            return
        }
        
        comm.invoke_method(method: m.method.info.id, context: .Document, args: [arg]) {
            reply in
            print("Message reply...");
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
    var list = [AvailableMethod]()
    
    func reset_list(_ l: [AvailableMethod]) {
        list.removeAll()
    }
}

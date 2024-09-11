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
            return current_doc_method_list.list
        } else {
            return current_doc_method_list.list.filter {
                $0.method.info.name.lowercased().contains(search_text.lowercased())
            }
        }
    }
    
    var body: some View {
        TextField("Search", text: $search_text)
    }
        
    
//        NavigationStack {
//            List(filtered_list) { item in
//                NavigationLink(item.method.info.name, value: item)
//            }
//            .navigationDestination(for: AvailableMethod.self) { item in
//                InvokeMethodView(method: item)
//            }
//        }
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
        HStack {
            if current_doc_method_list.list.contains(where: { $0.method.info.name == "noo::step_time" }) {
                Button() {
                    start_invoke("noo::step_time", CBOR(-1), .Document)
                } label: {
                    Label("Backward", systemImage: "backward.fill").labelStyle(.iconOnly)
                }
            }
            
            if current_doc_method_list.list.contains(where: { $0.method.info.name == "noo::animate_time" }) {
                Button() {
                    start_invoke("noo::animate_time", CBOR(0), .Document)
                } label: {
                    Label("Stop", systemImage: "stop.fill").labelStyle(.iconOnly)
                }
            }
            
            if current_doc_method_list.list.contains(where: { $0.method.info.name == "noo::animate_time" }) {
                Button() {
                    start_invoke("noo::animate_time", CBOR(1), .Document)
                } label: {
                    Label("Play", systemImage: "play.fill").labelStyle(.iconOnly)
                }
            }
            
            if current_doc_method_list.list.contains(where: { $0.method.info.name == "noo::step_time" }) {
                Button() {
                    start_invoke("noo::step_time", CBOR(1), .Document)
                } label: {
                    Label("Forward", systemImage: "forward.fill").labelStyle(.iconOnly)
                }
            }
        }
    }
    
    func start_invoke(_ target_name: String, _ arg: CBOR, _ target: InvokeMessageOn) {
        guard let comm = communicator else {
            return
        }
        
        let maybe_m = current_doc_method_list.list.first(where: { $0.method.info.name == target_name });
        
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
    var list = [AvailableMethod]()
    
    func reset_list(_ l: [AvailableMethod]) {
        list.removeAll()
    }
}

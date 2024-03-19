//
//  MethodList.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 3/14/24.
//

import Foundation
import SwiftUI

struct MethodListView : View {
    @EnvironmentObject var current_doc_method_list : MethodListObservable
    
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
    @EnvironmentObject var current_doc_method_list : MethodListObservable
    
    var body: some View {
        HStack {
            if current_doc_method_list.list.contains(where: { $0.method.info.name == "noo::step_time" }) {
                Button() {} label: {
                    Label("Backward", systemImage: "backward.fill")
                }
            }
            
            if current_doc_method_list.list.contains(where: { $0.method.info.name == "noo::animate_time" }) {
                Button() {} label: {
                    Label("Play", systemImage: "playpause.fill")
                }
            }
            
            if current_doc_method_list.list.contains(where: { $0.method.info.name == "noo::step_time" }) {
                Button() {} label: {
                    Label("Forward", systemImage: "forward.fill")
                }
            }
        }
    }
}

struct AvailableMethod: Identifiable {
    var id = UUID()
    var method: NooMethod
    var context: NooID?
    var context_type: String
}

class MethodListObservable : ObservableObject {
    @Published var list = [AvailableMethod]()
    
    func reset_list(_ l: [AvailableMethod]) {
        list.removeAll()
    }
}

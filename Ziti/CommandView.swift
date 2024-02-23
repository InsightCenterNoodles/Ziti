//
//  CommandView.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/13/24.
//

import SwiftUI

struct CommandView: View {
    @State private var hostname = ""
    @State private var is_bad_host = false
    
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack {
            Text("Ziti").font(.title2)
            Form {
                Section(header: Text("Connect to Specific Server")) {
                    TextField("Custom Address", text: $hostname).onSubmit {
                        do_connect()
                    }
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    Button("Connect", action: do_connect)
                        .alert("Hostname is not valid",
                               isPresented: $is_bad_host) {
                            Button("OK", role: .cancel) { }
                        }
                }
                
                Section(header: Text("Available Servers")) {
                    Text("Hi")
                }
            }
            Divider()
            NetBrowseView().frame(minHeight: 120)
        }.padding()
    }
    
    func do_connect() {
        print("Open window for \($hostname)")
        openWindow(id: "noodles_content_window", value: NewNoodles(hostname: hostname))
    }
}

struct CommandView_Previews: PreviewProvider {
    static var previews: some View {
        CommandView()
    }
}

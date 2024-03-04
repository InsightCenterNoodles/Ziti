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
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    var body: some View {
        VStack {
            Text("Ziti").font(.title2)
            HStack{
                VStack{
                    Text("Connect to a Server")
                    HStack {
                        TextField("Custom Address", text: $hostname).onSubmit {
                            do_connect()
                        }
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .textFieldStyle(.roundedBorder)
                        Button(action: do_connect){
                            Label("Connect", systemImage: "arrow.right").labelStyle(.iconOnly)
                        }
                        .alert("Hostname is not valid", isPresented: $is_bad_host) {
                            Button("OK", role: .cancel) { }
                        }
                    }.padding()
                    Divider()
                    VStack {
                        Text("Network Servers")
                        NetBrowseView().frame(minHeight: 120)
                    }
                }.frame(maxWidth: .infinity)
                Divider()
                Button("Close Immersive") {
                    Task {
                        await dismissImmersiveSpace()
                    }
                }.frame(maxWidth: .infinity)
            }
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

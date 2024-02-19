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
            HStack {
                TextField("Address", text: $hostname).onSubmit {
                    do_connect()
                }
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                
                Button(action: do_connect) {
                    Text("Connect")
                }
                .alert("Hostname is not valid",
                        isPresented: $is_bad_host) {
                    Button("OK", role: .cancel) { }
                }
            }
        }.padding().glassBackgroundEffect()
    }
    
    func do_connect() {
        print("Open window for \($hostname)")
        openWindow(id: "noodles_content_window", value: NewNoodles(hostname: hostname))
    }
}

#Preview {
    CommandView()
}

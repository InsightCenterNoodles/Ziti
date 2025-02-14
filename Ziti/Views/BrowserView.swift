//
//  CommandView.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/13/24.
//

import SwiftUI

struct BrowserView: View {
    @State private var hostname = ""
    @State private var is_bad_host = false
    @State var user_name = "Unknown"
    @State var previous_custom = [String]()
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    
    var long_press_delete_all: some Gesture {
        LongPressGesture(minimumDuration: 1.0).onEnded {
            _ in
            previous_custom.removeAll()
        }
    }
    
    var body: some View {
        TabView {
            VStack {
                Text("Network Servers")
                NetBrowseView().frame(minHeight: 120)
            }.tabItem {
                Label("Network Servers", systemImage: "network")
            }
            
            VStack {
                HStack {
                    TextField("Custom Address", text: $hostname).onSubmit {
                        do_connect()
                    }
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.roundedBorder)
                    
                    Menu() {
                        Button() {
                            launch_small_window()
                        } label: {
                            Label("Small Space", systemImage: "widget.small")
                        }
                        Button() {
                            launch_window()
                        } label: {
                            Label("Large Space", systemImage: "widget.extralarge")
                        }
                        Divider()
                        Button() {
                            launch_immersive()
                        } label: {
                            Label("Immersive", systemImage: "sharedwithyou.circle.fill")
                        }
                        
                    } label: {
                        Label("Connect", systemImage: "plus").labelStyle(.iconOnly)
                    }.menuStyle(.borderlessButton)
                    .alert("Hostname is not valid", isPresented: $is_bad_host) {
                        Button("OK", role: .cancel) { }
                    }
                    
                }.padding()
                List {
                    ForEach(previous_custom, id: \.self) { item in
                        Text(item).swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                if let index = previous_custom.firstIndex(of: item) {
                                    previous_custom.remove(at: index)
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }.gesture(long_press_delete_all)
            }
            .tabItem {
                Label("Custom", systemImage: "rectangle.connected.to.line.below")
            }
            
            Form {
                Section("Identity") {
                    TextField("Name", text: $user_name)
                }
                Section("Misc") {
                    Button("Stop Immersive") {
                        Task {
                            await dismissImmersiveSpace()
                        }
                    }
                }
            }.tabItem {
                Label("User", systemImage: "person.circle.fill")
            }
        }.padding().glassBackgroundEffect()
    }
    
    func do_connect() {
        print("Open window for \($hostname)")
        
        guard (URL(string: hostname)?.host()) != nil else {
            print("Invalid host")
            return
        }
        
        openWindow(id: "noodles_content_window", value: NewNoodles(hostname: hostname))
        previous_custom.append(hostname)
        hostname = ""
        if previous_custom.count > 25 {
            let _ = previous_custom.popLast()
        }
    }
    
    func get_host() -> String {
        return hostname
    }
    
    func launch_small_window() {
        print("Launching window")
        let host = "ws://\(get_host())"
        openWindow(id: "noodles_content_window_small", value: NewNoodles(hostname: host))
        dismissWindow(id: "noodles_browser")
    }
    
    func launch_window() {
        print("Launching window")
        let host = "ws://\(get_host())"
        openWindow(id: "noodles_content_window", value: NewNoodles(hostname: host))
        dismissWindow(id: "noodles_browser")
    }
    
    func launch_immersive() {
        print("Launching immersive window")
        let host = "ws://\(get_host())"
        
        Task {
            let result = await openImmersiveSpace(id: "noodles_immersive_space", value: NewNoodles(hostname: host))
            
            if case .error = result {
                print("An error occurred")
            }
        }
        
        dismissWindow(id: "noodles_browser")
    }
}

struct CommandView_Previews: PreviewProvider {
    static var previews: some View {
        BrowserView()
    }
}

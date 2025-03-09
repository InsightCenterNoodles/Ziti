//
//  CommandView.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/13/24.
//

import SwiftUI

struct BrowserView: View {
    @State private var hostname = ""
    @State var user_name = "Unknown"
    @State var is_bad_host: Bool = false
    
    @State var showing_delete_all_alert: Bool = false
    
    @StateObject private var custom_entries = CustomEntries()
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    
    var long_press_delete_all: some Gesture {
        LongPressGesture(minimumDuration: 1.0).onEnded {
            _ in
            custom_entries.remove_all_items()
        }
    }
    
    var body: some View {
        TabView {
            NetworkServersView().tabItem {
                Label("Network Servers", systemImage: "network")
            }
            
            CustomAddressView(hostname:$hostname, is_bad_host: $is_bad_host, custom_entries: custom_entries ) {
                custom_entries.add_item(hostname)
            }
            .tabItem {
                Label("Custom", systemImage: "rectangle.connected.to.line.below")
            }
            
            UserSettingsView(user_name: $user_name) {
                Task {
                    await dismissImmersiveSpace()
                }
            }
            .tabItem {
                Label("User", systemImage: "person.circle.fill")
            }
        }.padding().glassBackgroundEffect()
    }
    
    func do_connect() {
        print("Open window for \($hostname)")
        
        guard let url = URL(string: normalize_websocket_url(hostname)), url.host != nil else {
            print("Invalid host")
            return
        }
        
        openWindow(id: "noodles_content_window", value: NewNoodles(hostname: hostname))
        custom_entries.add_item(hostname)
        hostname = ""
        if custom_entries.items.count > 25 {
            custom_entries.items.removeFirst()
        }
    }
    
    func get_host() -> String {
        return hostname
    }
    
    func launch_small_window() {
        print("Launching window")
        let host = normalize_websocket_url(get_host())
        openWindow(id: "noodles_content_window_small", value: NewNoodles(hostname: host))
        dismissWindow(id: "noodles_browser")
    }
    
    func launch_window() {
        print("Launching window")
        let host = normalize_websocket_url(get_host())
        openWindow(id: "noodles_content_window", value: NewNoodles(hostname: host))
        dismissWindow(id: "noodles_browser")
    }
    
    func launch_immersive() {
        print("Launching immersive window")
        let host = normalize_websocket_url(get_host())
        
        Task {
            let result = await openImmersiveSpace(id: "noodles_immersive_space", value: NewNoodles(hostname: host))
            
            if case .error = result {
                print("An error occurred")
            }
        }
        
        dismissWindow(id: "noodles_browser")
    }
}

struct NetworkServersView: View {
    var body: some View {
        VStack {
            Text("Network Servers")
            NetBrowseView().frame(minHeight: 120)
        }
    }
}

struct UserSettingsView: View {
    @Binding var user_name: String
    var stopImmersiveAction: () -> Void
    
    var body: some View {
        Form {
            Section("Identity") {
                TextField("Name", text: $user_name)
            }
            Section("Misc") {
                Button("Stop Immersive") {
                    stopImmersiveAction()
                }
            }
        }
    }
}

func normalize_websocket_url(_ hostname: String) -> String {
    var normalized = hostname.trimmingCharacters(in: .whitespacesAndNewlines)

    if !normalized.hasPrefix("ws://") && !normalized.hasPrefix("wss://") {
        normalized = "ws://" + normalized
    }
    
    if let urlComponents = URLComponents(string: normalized), urlComponents.port == nil {
        normalized += ":50000"
    }

    return normalized
}

struct CommandView_Previews: PreviewProvider {
    static var previews: some View {
        BrowserView()
    }
}

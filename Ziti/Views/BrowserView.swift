//
//  CommandView.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/13/24.
//

import SwiftUI

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


struct Server: Identifiable, Encodable, Decodable, Hashable {
    let id: UUID
    var name: String
    var ipAddress: String
    let discovered: Bool
}

struct BrowserView: View {
    @ObservedObject var custom_entries = CustomEntries()
    @ObservedObject var network_browser = NooServerListener()
    
    @State private var path = NavigationPath()
    
    @State var hostname: String = ""
    @State var is_bad_host = false
    @State var search_text: String = ""

    @Environment(\.dismiss) private var dismiss
    
    var filter_custom : [Server] {
        if self.search_text.isEmpty {
            return custom_entries.items
        }

        return custom_entries.items.filter {
            $0.name.localizedCaseInsensitiveContains(search_text)
        }
    }
    
    var filter_discovered : [Server] {
        if self.search_text.isEmpty {
            return network_browser.dest
        }

        return network_browser.dest.filter {
            $0.name.localizedCaseInsensitiveContains(search_text)
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            Form {
                Section {
                    HStack {
                        TextField("Server Address (e.g. ws://example.com:50000)",
                                  text: $hostname)
                        .onSubmit {
                            validate_and_submit()
                        }
                        .disableAutocorrection(true)
                        .textInputAutocapitalization(.never)
                        .foregroundColor(is_bad_host ? .red : .primary)
                        
                        Button(action: {
                            validate_and_submit()
                        }) {
                            Label("Add Favorite", systemImage: "plus").labelStyle(.iconOnly)
                        }
                        .disabled(hostname.isEmpty)
                        .alert("Invalid WebSocket Address", isPresented: $is_bad_host) {
                            Button("OK", role: .cancel) { }
                        }
                        
                    }
                }
                
                List(filter_custom) { server in
                    NavigationLink(value: server) {
                        ServerEntry(server: server)
                    }
                }
                
                List(filter_discovered) { server in
                    NavigationLink(value: server) {
                        ServerEntry(server: server)
                    }
                }
            }
            .navigationTitle("Server List")
            .navigationDestination(for: Server.self) { server in
                ServerActionView(server: server, custom_entries: custom_entries) {
                    path.removeLast()
                }
            }
        }
        .listStyle(.grouped)
        .navigationSplitViewStyle(.prominentDetail)
        .searchable(text: $search_text)
        .onAppear() {
            network_browser.startDiscovery()
        }.onDisappear() {
            network_browser.stopDiscovery()
        }.onChange(of: path) {
            dump(path)
        }
    }
    
    private func validate_and_submit() {
        let normalized = normalize_websocket_url(hostname)
        
        guard let url = URL(string: normalized), url.host != nil else {
            is_bad_host = true
            print("Invalid host")
            return
        }
        
        is_bad_host = false
        
        let host = URL(string: normalized)?.host() ?? "New Entry"
        
        custom_entries.add_item(Server(id: UUID(), name: host, ipAddress: normalized, discovered: false))
    }
}

struct ServerActionView: View {
    @State var server: Server
    @ObservedObject var custom_entries: CustomEntries
    
    @State var is_editing = false
    
    @State private var server_name: String = ""
    @State private var server_address: String = ""
    
    //@Environment(\.dismiss) var dismiss
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    //@Environment(\.dismissWindow) private var dismissWindow

    var onDismiss: (() -> Void)
    
    var body: some View {
        VStack {
            if is_editing {
                Form {
                    Section(header: Text("Server Name")) {
                        TextField("Edit Name", text: $server_name)
                        
                    }
                    
                    Section(header: Text("Server Address")) {
                        TextField("Edit Address", text: $server_address)
                    }
                    
                }.formStyle(.grouped)
            } else {
                Text(server.name).font(.title)
                Text(server.ipAddress).font(.subheadline).foregroundStyle(.secondary)
            }
            
            Divider()
            
            if !is_editing {
                Text("Choose a content view:").foregroundStyle(.secondary)
                
                Grid {
                    GridRow {
                        LargeButton(label: "Small Window", icon: "widget.small") {
                            openWindow(id: "noodles_content_window_small", value: NewNoodles(hostname: normalize_websocket_url(server.ipAddress)))
                            onDismiss()
                        }.frame(width: 140, height: 140)
                        
                        LargeButton(label: "Large Window", icon: "widget.large") {
                            openWindow(id: "noodles_content_window", value: NewNoodles(hostname: normalize_websocket_url(server.ipAddress)))
                            onDismiss()
                        }.frame(width: 140, height: 140)
                        
                        LargeButton(label: "Immersive View", icon: "sharedwithyou.circle.fill") {
                            Task {
                                let result = await openImmersiveSpace(id: "noodles_immersive_space", value: NewNoodles(hostname: normalize_websocket_url(server.ipAddress)))
                    
                                if case .error = result {
                                    print("An error occurred")
                                }
                            }
                    
                            onDismiss()
                        }.frame(width: 140, height: 140)
                    }
                    
                }
                
                Spacer()
                
                VStack(alignment: .leading) {
                    Text("• **Small Window**: A compact 0.5m volume.")
                    Text("• **Large Window**: A larger 1m volume.")
                    Text("• **Immersive Mode**: Takes over the whole display.")
                    Text("Only **one** immersive mode can be active at a time.")
                        .foregroundColor(.red)
                }
                
                
            }
            
            
            Spacer()
            
            if is_editing {
                Button(role: .destructive) {
                    if let index = get_custom_index() {
                        onDismiss()
                        custom_entries.remove_item(at: index)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if server.discovered {
                Text("This server was automatically discovered and cannot be modified.").font(.caption).foregroundColor(.secondary)
            }
            
        }.toolbar {
            if !server.discovered {
                if is_editing {
                    Button {
                        is_editing = false
                    } label: {
                        Label("Cancel", systemImage: "arrow.counterclockwise")
                    }
                    
                    Button {
                        is_editing = false
                        save_edits()
                    } label: {
                        Label("Done", systemImage: "checkmark.circle.fill")
                    }
                    
                } else {
                    Button {
                        is_editing = true
                        
                        server_name = server.name
                        server_address = server.ipAddress
                        
                    } label: {
                        Label("Edit", systemImage: "square.and.pencil")
                    }.buttonStyle(.borderless)
                }
            }
        }
        .padding()
        .animation(.easeInOut, value: is_editing)
        
    }
    
    func get_custom_index() -> Int? {
        custom_entries.items.firstIndex (where: {
            $0.id == server.id
        })
    }
    
    func save_edits() {
        guard let index = get_custom_index() else { return }
        
        custom_entries.items[index].name = server_name
        custom_entries.items[index].ipAddress = normalize_websocket_url(server_address)
        
        server = custom_entries.items[index]
    }
}

struct ServerEntry: View {
    let server: Server
    
    var body: some View {
        HStack {
            VStack {
                Text(server.name)
                    .font(.headline).frame(maxWidth:.infinity, alignment: .leading)
                
                Text(server.ipAddress)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            if server.discovered {
                Label("Discovered", systemImage: "person.crop.badge.magnifyingglass").labelStyle(.iconOnly)
            }
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        BrowserView().frame(maxWidth: 500).glassBackgroundEffect()
    }
}


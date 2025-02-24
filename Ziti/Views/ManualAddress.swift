//
//  ManualAddress.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/21/25.
//

import SwiftUI


struct CustomAddressView: View {
    @Binding var hostname: String
    @Binding var is_bad_host: Bool
    @ObservedObject var custom_entries: CustomEntries
    var onSubmit: () -> Void
    
    var body: some View {
        VStack {
            HStack {
                TextField("Custom WebSocket Address (e.g., ws://example.com:50000)", text: $hostname)
                    .onSubmit {
                        validate_and_submit()
                    }
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.roundedBorder)
                    .foregroundColor(is_bad_host ? .red : .primary)
                
                Button(action: {
                    validate_and_submit()
                }) {
                    Label("Connect", systemImage: "plus").labelStyle(.iconOnly)
                }
                .disabled(hostname.isEmpty)
                .alert("Invalid WebSocket Address", isPresented: $is_bad_host) {
                    Button("OK", role: .cancel) { }
                }
            }
            .padding()
            
            CustomEntriesListView(custom_entries: custom_entries)
        }
    }
    
    private func validate_and_submit() {
        guard let url = URL(string: normalize_websocket_url(hostname)), url.host != nil else {
            is_bad_host = true
            print("Invalid host")
            return
        }
        
        is_bad_host = false
        onSubmit()
    }
}

struct CustomEntriesListView: View {
    @ObservedObject var custom_entries: CustomEntries
    @State private var editMode: EditMode = .inactive
    
    var body: some View {
        List {
            ForEach(custom_entries.items, id: \.self) { item in
                CustomEntryRowView(item: item, custom_entries: custom_entries)
            }
            .onMove(perform: move)
        }
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
        }
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        custom_entries.items.move(fromOffsets: source, toOffset: destination)
    }
}

struct CustomEntryRowView: View {
    let item: String
    @ObservedObject var custom_entries: CustomEntries
    @State private var isEditing: Bool = false
    @State private var editedText: String = ""
    
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissWindow) private var dismissWindow
    
    var body: some View {
        HStack {
            if isEditing {
                TextField("Edit Address", text: $editedText, onCommit: {
                    saveEdit()
                })
                .textFieldStyle(.roundedBorder)
            } else {
                Text(item)
                Spacer()
                Divider()
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
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                if let index = custom_entries.items.firstIndex(of: item) {
                    custom_entries.removeItem(at: index)
                }
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                isEditing.toggle()
                editedText = item
            } label: {
                Label("Edit", systemImage: "pencil")
            }
        }
    }
    
    func launch_small_window() {
        print("Launching window")
        let host = normalize_websocket_url(item)
        openWindow(id: "noodles_content_window_small", value: NewNoodles(hostname: host))
        dismissWindow(id: "noodles_browser")
    }
    
    func launch_window() {
        print("Launching window")
        let host = normalize_websocket_url(item)
        openWindow(id: "noodles_content_window", value: NewNoodles(hostname: host))
        dismissWindow(id: "noodles_browser")
    }
    
    func launch_immersive() {
        print("Launching immersive window")
        let host = normalize_websocket_url(item)
        
        Task {
            let result = await openImmersiveSpace(id: "noodles_immersive_space", value: NewNoodles(hostname: host))
            
            if case .error = result {
                print("An error occurred")
            }
        }
        
        dismissWindow(id: "noodles_browser")
    }
    
    private func saveEdit() {
        if let index = custom_entries.items.firstIndex(of: item) {
            custom_entries.items[index] = editedText
            custom_entries.saveItems()
        }
        isEditing.toggle()
    }
}

class CustomEntries: ObservableObject {
    @AppStorage("previous_custom_items") private var savedItems: Data = Data()
    @Published var items: [String] = []
    
    init() {
        loadItems()
    }
    
    func addItem(_ item: String) {
        items.append(item)
        saveItems()
    }
    
    func removeItem(at index: Int) {
        items.remove(at: index)
        saveItems()
    }
    
    func removeAllItems() {
        items.removeAll()
        saveItems()
    }
    
    func saveItems() {
        if let data = try? JSONEncoder().encode(items) {
            savedItems = data
        }
    }
    
    private func loadItems() {
        if let decodedItems = try? JSONDecoder().decode([String].self, from: savedItems) {
            items = decodedItems
        }
    }
}

struct CustomAddressTab: View {
    @State var hostname: String = ""
    @State var is_bad_host: Bool = false
    @ObservedObject var custom_entries = CustomEntries()
    
    var body: some View {
        VStack {
            CustomAddressView(hostname:$hostname, is_bad_host: $is_bad_host, custom_entries: custom_entries ) {
                custom_entries.addItem(hostname)
            }
        }
    }
}

#Preview {
    CustomAddressTab().glassBackgroundEffect()
}

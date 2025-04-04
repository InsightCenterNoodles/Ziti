//
//  ImmersiveControls.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/10/25.
//

import SwiftUI
import ZitiCore
import SwiftCBOR
import RealityFoundation

struct ImmersiveControls : View {
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    @Environment(\.openWindow) private var openWindow
    
    @EnvironmentObject var image_model: ImageTrackingViewModel
    @EnvironmentObject var info_model: ControlInfoModel
    
    @Binding var communicator: NoodlesCommunicator?
    
    @State private var show_image_tracking: Bool = false
    
    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    Spacer()
                    CompactMethodView(communicator: $communicator)
                    Spacer()
                }
                Section {
                    VStack {
                        Picker("Interaction", selection: $info_model.interaction) {
                            Text("Locked").tag(ControlInteractionMode.none)
                            Text("Items").tag(ControlInteractionMode.item)
                            Text("Scene").tag(ControlInteractionMode.root)
                        }.pickerStyle(.segmented)
                        
                        if info_model.interaction == .root {
                            LargeToggleButton(
                                isOn: $info_model.lock_scene_rotation,
                                label: "Lock Scene Rotation",
                                onIcon: "lock.rotation",
                                offIcon: "lock.open.rotation"
                            )
                            LargeToggleButton(
                                isOn: $info_model.lock_scene_scale,
                                label: "Lock Scene Scale",
                                onIcon: "scale.3d",
                                offIcon: "scale.3d"
                            )
                        }
                    }
                }
                
                HStack {
                    LargeButton(label: "Reset Scene", icon: "repeat") {
                        communicator?.world.root_entity.transform = Transform();
                    }
                    
                    LargeButton(label: "New Connection", icon: "note.text.badge.plus"){
                        openWindow(id: "noodles_browser")
                    }
                }
                
                Spacer()
                
                ImmersiveMethodView(communicator: $communicator)
                
                Divider()
                
                HStack {
                    NavigationLink() {
                        ImmersiveSettingsView()
                    } label: {
                        VStack {
                            Image(systemName: "photo.artframe.circle.fill")
                            Text("Image Tracking")
                        }
                    }.buttonBorderShape(.roundedRectangle(radius: 8))
                    
                    LargeToggleButton(
                        isOn: $info_model.scene_reconstruct,
                        label: "World Occlusion",
                        onIcon: "eye.fill",
                        offIcon: "eye.slash.fill"
                    )
                }
                
                Spacer()
                
                Divider()
                
                Button(role: .destructive) {
                    Task {
                        print("Close immersive")
                        await dismissImmersiveSpace()
                    }
                } label: {
                    Text("Close")
                }.buttonStyle(.borderless).frame(maxWidth: .infinity)
                
            }.formStyle(.columns)
        }
        .frame(minWidth: 100, maxWidth: 400, minHeight: 100, maxHeight: 800).padding().glassBackgroundEffect()
    }
}

struct InlineToggleButton: View {
    @Binding var isOn: Bool
    var label: String
    var onIcon: String
    var offIcon: String
    var activeColor: Color = .green
    var inactiveColor: Color = .red

    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            Label(label, systemImage: isOn ? onIcon : offIcon)
            .foregroundColor(isOn ? activeColor : inactiveColor)
        }
    }
}

struct LargeToggleButton: View {
    @Binding var isOn: Bool
    var label: String
    var onIcon: String
    var offIcon: String
    var activeColor: Color = .green
    var inactiveColor: Color = .red

    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            VStack {
                Image(systemName: isOn ? onIcon : offIcon)
                Text(label)
            }
            .foregroundColor(isOn ? activeColor : inactiveColor)
        }.buttonBorderShape(.roundedRectangle(radius: 8))
    }
}

struct LargeButton : View {
    var label: String
    var icon: String
    var action: () -> Void
    
    var body: some View {
        Button(action: self.action) {
            VStack {
                Spacer(minLength: 0)
                Image(systemName: icon).padding()
                Text(label).frame(maxWidth: .infinity)
                Spacer(minLength: 0)
            }.multilineTextAlignment(.center)
        }.buttonBorderShape(.roundedRectangle(radius: 8))
    }
}

struct ImmersiveSettingsView : View {
    @EnvironmentObject var image_model: ImageTrackingViewModel
    
    var body: some View {
        VStack {
            Grid() {
                GridRow {
                    LargeToggleButton(
                        isOn: $image_model.is_tracking,
                        label: "Enable Tracking",
                        onIcon: "checkmark.circle.fill",
                        offIcon: "circle"
                    )
                    LargeToggleButton(
                        isOn: $image_model.maintain_vertical,
                        label: "Vertical Lock",
                        onIcon: "lock.fill",
                        offIcon: "lock.open",
                        activeColor: .blue
                    )
                }
                
            }
            Spacer()
        }
        .navigationTitle("Image Tracking") // Adds a title like iOS settings
        .navigationBarTitleDisplayMode(.inline) // Keeps the title compact
    }
}

struct ImmersiveMethodView : View {
    @Environment(MethodListObservable.self) var current_doc_method_list
    
    @Binding var communicator: NoodlesCommunicator?
    
    var filtered_list : [AvailableMethod] {
        return current_doc_method_list.available_methods.filter {
            !$0.name.contains("noo::")
        }
    }
    
    var body: some View {
        List(filtered_list, id: \.self) { item in
            Button(action: {
                start_invoke(item.name, [], .Document)
            }) {
                Text(item.name)
            }
            
        }
    }
    
    public func start_invoke(_ target_name: String, _ arg: [CBOR], _ target: InvokeMessageOn) {
        guard let comm = communicator else {
            return
        }
        
        let maybe_m = current_doc_method_list.find_by_name(target_name);
        
        guard let m = maybe_m else {
            return
        }
        
        comm.invoke_method(method: m.noo_id, context: target, args: arg) {
            reply in
            print("Message reply: ", reply);
        }
    }
}

//#Preview(windowStyle: .plain) {
//    TestView()
//}


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
    
    
    
    var body: some View {
        NavigationStack {
            // cant get this to work yet
            //Text(tex info_model.title_text)
            
            Form {
                HStack {
                    Spacer()
                    CompactMethodView(communicator: $communicator)
                    Spacer()
                }
                
                ImmersiveMethodView(communicator: $communicator)
                
                Section() {
                    NavigationLink() {
                        SceneRootEditorView(communicator: $communicator)
                    } label: {
                        Label("Scene Anchoring", systemImage: "gyroscope")
                    }.frame(maxWidth: .infinity).foregroundStyle(.primary)
                    
                    NavigationLink() {
                        ImmersiveViewOptions()
                    } label: {
                        Label("View Options", systemImage: "eye.fill")
                    }.frame(maxWidth: .infinity).foregroundStyle(.primary)
                    
                    Button {
                        openWindow(id: "noodles_browser")
                    } label: {
                        Label("Add Connection", systemImage: "note.text.badge.plus")
                    }.frame(maxWidth: .infinity).foregroundStyle(.primary)
                }
            }
            
            Divider()
            
            Button(role: .destructive) {
                Task {
                    print("Close immersive")
                    await dismissImmersiveSpace()
                }
            } label: {
                Text("Close")
            }.buttonStyle(.borderless).frame(maxWidth: .infinity)
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
            VStack(spacing: 4) {
                Image(systemName: icon).font(.title).padding()
                Text(label)
            }
            .frame(minWidth: 120, minHeight: 60)
            .multilineTextAlignment(.center)
        }.buttonBorderShape(.roundedRectangle(radius: 8))
    }
}

struct ImmersiveViewOptions : View {
    @EnvironmentObject var info_model: ControlInfoModel
    
    var body: some View {
        Form {
            Toggle("World Occlusion", isOn: $info_model.scene_reconstruct)
        }.navigationTitle("Immersive View Options")
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

struct SceneRootEditorView : View {
    @EnvironmentObject var info_model: ControlInfoModel
    @EnvironmentObject var image_model: ImageTrackingViewModel
    @EnvironmentObject var finger_model: FingerTrackingViewModel
    @Binding var communicator: NoodlesCommunicator?
    
    //@State private var show_image_tracking: Bool = false
    
    @State private var previous_world_occlude: Bool = false
    
    var body: some View {
        
        Form {
            Text("The scene anchor can be moved to align with real world objects by pinching and dragging, or using the double-pinch gesture.").font(.subheadline).foregroundStyle(.secondary)
            
            Section(header: Text("Scene Control Options")) {
                Toggle("Keep Horizontal", isOn: $info_model.lock_scene_rotation)
                Toggle("Scale Lock", isOn: $info_model.lock_scene_scale)
                Text("Limit rotation to vertical axis and prevent 'double pinch' scaling.").font(.caption).foregroundStyle(.secondary)
            }
            
            Section(header: Text("Image Tracking")) {
                Toggle("Track Anchor Image", isOn: $image_model.is_tracking)
                
                if image_model.is_tracking {
                    Text("Look at a QR or ARuCO code briefly to set the anchor's location. The horizontal axis can be locked to the vertical.").font(.caption).foregroundStyle(.secondary)
                    
                    Toggle("Horizontal Only", isOn: $image_model.maintain_vertical)
                }
            }
            
            Section {
                Button {
                    reset_scene_to_head()
                } label: {
                    Label("Anchor to Right Thumb", systemImage: "arrowshape.left.arrowshape.right.fill").foregroundStyle(.primary)
                }.frame(maxWidth: .infinity)
            }
            
            Section {
                Button(role: .destructive) {
                    communicator?.world.root_entity.move(to: Transform(), relativeTo: nil, duration: 2)
                } label: {
                    Label("Reset Anchor", systemImage: "repeat").foregroundStyle(.primary)
                }.frame(maxWidth: .infinity)
            }
            
        }.onAppear {
            info_model.root_interaction_allowed = true
            finger_model.head_indicator_entity.isEnabled = true
            
            previous_world_occlude = info_model.scene_reconstruct
            info_model.scene_reconstruct = false
            image_model.is_tracking = true
            
            
        }.onDisappear {
            info_model.root_interaction_allowed = false
            finger_model.head_indicator_entity.isEnabled = false
            
            info_model.scene_reconstruct = previous_world_occlude
            
            image_model.is_tracking = false
        }
        .navigationTitle("Scene Anchor Editing")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func reset_scene_to_head() {
        let new_pos = finger_model.head_indicator_entity.position(relativeTo: nil)
        
        var new_tf = Transform()
        
        new_tf.translation = new_pos;
        
        communicator?.world.root_entity.move(to: new_tf, relativeTo: nil, duration: 2)
    }
}


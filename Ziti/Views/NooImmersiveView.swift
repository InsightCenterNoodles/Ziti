//
//  ContentView.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/29/24.
//

import SwiftUI
import RealityKit
import RealityKitContent
import ARKit

import ZitiCore
import Combine

struct NooImmersiveView: View {
    var new_noodles_config : NewNoodles!
    
    @State private var reconstruction_model = SceneReconstructionModel()
    
    @State private var noodles_state : NoodlesCommunicator?
    @State private var noodles_world : NoodlesWorld?
    @State private var is_bad_host = false
    
    @State private var global_scale = 1.0
    @State private var auto_extent = false
    
    @State private var current_scene : RealityViewContent!
    @State private var current_root: Entity!
    @State private var current_doc_method_list = MethodListObservable()
    
    @ObservedObject var image_model: ImageTrackingViewModel = ImageTrackingViewModel()
    @StateObject private var info_model = ControlInfoModel()
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    init(new: NewNoodles) {
        new_noodles_config = new
    }
    
    var body: some View {
        RealityView { content, attachments in
            self.current_scene = content
            
            current_root = Entity()
            current_root.name = "ImmersiveRoot"
            
            image_model.start()
            image_model.root_entity = current_root
            
            content.add(reconstruction_model.contentRoot)
            
            content.add(current_root)
            
            let u = URL(string: new_noodles_config.hostname) ?? URL(string: "ws://localhost:50000")!
            
            let error_entity = try! await Entity(named: "NoConnection", in: realityKitContentBundle)
            content.add(error_entity)
            
            noodles_world = await NoodlesWorld(
                current_root,
                error_entity,
                current_doc_method_list,
                initial_offset: simd_float3([0, 1, 0])
            )
            
            noodles_state = NoodlesCommunicator(url: u, world: noodles_world!)
            
            noodles_world?.comm = noodles_state
            
            let anchor = AnchorEntity(.hand(.left, location: .wrist), trackingMode: .predicted)
            anchor.name = "hand_anchor"
            
            content.add(anchor)
            
            if let att = attachments.entity(for: "hand_label") {
                att.position = .init([0.0, 0.0, -0.15])
                
                let zRotation = simd_quaternion(-Float.pi / 2, simd_float3(0, 0, 1))
                let xRotation = simd_quaternion(Float.pi / 2, simd_float3(1, 0, 0))
                
                att.transform.rotation = xRotation * zRotation
                //att.transform.rotation = zRotation
                att.transform.scale = .init(repeating: 0.6)

                anchor.addChild(att)
            }
            
            
        } attachments: {
            Attachment(id: "hand_label") {
                ImmersiveControls(communicator: $noodles_state).environment(current_doc_method_list).environmentObject(image_model).environmentObject(info_model)
                
            }
        } .installGestures()
        .onChange(of: info_model.interaction) {
            var root_visible = false
            
            switch info_model.interaction {
            case .none:
                noodles_world?.set_all_entity_input(enabled: false)
            case .root:
                noodles_world?.set_all_entity_input(enabled: false)
                root_visible = true
            case .item:
                noodles_world?.set_all_entity_input(enabled: true)
            }
            
            noodles_world?.root_controller.isEnabled = root_visible
        } .onChange(of: info_model.lock_scene_rotation) {
            noodles_world?.root_controller.components[GestureComponent.self]?.lockRotateUpAxis = info_model.lock_scene_rotation
        } .onChange(of: info_model.scene_reconstruct) {
            reconstruction_model.contentRoot.isEnabled = info_model.scene_reconstruct
        } .task(priority: .low) {
            reconstruction_model.start()
            await reconstruction_model.processReconstruction()
        } .task {
            await reconstruction_model.monitorSessionEvents()
        }
    }
    
    func frame_all() {
        auto_extent = true
        
        noodles_state?.world.frame_all(target_volume: SIMD3<Float>(2,1,2))
    }
}


@Observable
@MainActor
class ARKitManager {
    static let shared = ARKitManager()
    
    let session = ARKitSession()
    let sceneReconstruction = SceneReconstructionProvider()
    
    var is_started = false
    
    /// Provider of tracked images
    let image_info = ImageTrackingProvider(
        referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "TrackingImages")
    )
    
    func start() {
        guard is_started == false else { return }
        
        var providers : [any DataProvider] = []
        
        if SceneReconstructionProvider.isSupported {
            print("Reconstruction supported")
            
            if sceneReconstruction.state == .initialized {
                print("Reconstruction able to start")
                
                providers.append(sceneReconstruction)
                
            }
        }
        
        if ImageTrackingProvider.isSupported {
            print("Image tracking supported")
            providers.append(image_info)
        }
        
        is_started = true
        
        Task {
            try await session.run(providers)
        }
    }
}


/// Models tracked images (QR codes). When images are detected, we add an entity to it in the world, and move the root
/// of the NOODLES scene to this entity as a child
@MainActor
class ImageTrackingViewModel: ObservableObject {
    /// The AR Kit session to scan the room
    private let session = ARKitManager.shared
    
    /// This is the entity we will manage. We want to move the NOODLES root to the QR code
    public var root_entity : Entity?
    
    /// Turn tracking on and off
    @Published public var is_tracking: Bool = false
    
    public var did_init: Bool = false
    
    /// We can squash all rotations except for the yaw of the image.
    @Published public var maintain_vertical: Bool = false
    
    
    
    /// When an image is detected we add it as an entity here
    var entity_map: [UUID: Entity] = [:]
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        $is_tracking.sink { new_value in
            if new_value {
                self.start()
            }
        }.store(in: &cancellables)
    }
    
    func start() {
        session.start()
        entity_map.removeAll()
        if did_init { return }
        
        Task {
            for await update in session.image_info.anchorUpdates {
                await update_image(update.anchor)
            }
        }
        
        did_init = true
    }
    
    func update_image(_ anchor: ImageAnchor) async {
        
        if !is_tracking {
            return
        }
        
        // at the moment, we only work with ONE. Eventually we will remove this with NOODLES2.
        let description = anchor.id
        
        if entity_map[description] == nil {
            // Add a new entity to represent this image.
            print("Adding new image")
            
            if let new_entity = try? await Entity(named: "LocationIndicator", in: realityKitContentBundle) {
                new_entity.name = "Tracked Image Reference"
                entity_map[description] = new_entity
                
                if let root = self.root_entity {
                    root.addChild(new_entity)
                }
            } else {
                print("Unable to load image graphics")
            }
        }
        
        if anchor.isTracked {
            let matrix = maintain_vertical ? preserve_yaw_only(from: anchor.originFromAnchorTransform) : anchor.originFromAnchorTransform
            self.root_entity?.transform = Transform(matrix: matrix)
            
            // since we control the root now, remove any initial offset
            self.root_entity?.children.first?.position = .zero
        }
    }
}

private func preserve_yaw_only(from matrix: simd_float4x4) -> simd_float4x4 {
    // Extract the forward vector (Z-axis of the QR code)
    let forward = simd_normalize(simd_float3(matrix.columns.2.x, 0, matrix.columns.2.z))
    
    // Extract right vector (X-axis) perpendicular to forward
    let right = simd_cross(simd_float3(0, 1, 0), forward)
    
    // Y-axis remains the world up direction (0,1,0)
    let up = simd_float3(0, 1, 0)
    
    // Construct the new rotation matrix
    var ret = matrix
    ret.columns.0 = simd_float4(right, 0)  // X-axis
    ret.columns.1 = simd_float4(up, 0)     // Y-axis (remains unchanged)
    ret.columns.2 = simd_float4(forward, 0) // Z-axis (flattened to horizontal)
    
    return ret
}

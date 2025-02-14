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

struct NooImmersiveView: View {
    var new_noodles_config : NewNoodles!
    
    @State private var noodles_state : NoodlesCommunicator?
    @State private var noodles_world : NoodlesWorld?
    @State private var is_bad_host = false
    
    @State private var global_scale = 1.0
    @State private var auto_extent = false
    
    @State private var current_scene : RealityViewContent!
    @State private var current_root: Entity!
    @State private var current_doc_method_list = MethodListObservable()
    
    @ObservedObject var image_model: ImageTrackingViewModel = ImageTrackingViewModel()
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    init(new: NewNoodles) {
        new_noodles_config = new
    }
    
    var body: some View {
        RealityView { content, attachments in
            self.current_scene = content
            
            current_root = Entity()
            
            await image_model.start()
            
            image_model.root_entity = current_root
            
            content.add(current_root)
            
            let u = URL(string: new_noodles_config.hostname) ?? URL(string: "ws://localhost:50000")!
            
            noodles_world = await NoodlesWorld(current_root, current_doc_method_list, initial_offset: simd_float3([0, 1, 0]))
            
            noodles_state = NoodlesCommunicator(url: u, world: noodles_world!)
            
            noodles_world?.comm = noodles_state
            
            let anchor = AnchorEntity(.hand(.left, location: .wrist), trackingMode: .continuous)
            anchor.name = "hand_anchor"
            
            content.add(anchor)
            
            if let att = attachments.entity(for: "hand_label") {
                //att.components[BillboardComponent.self] = .init()
                att.position = .init([0.0, 0.0, -0.1])
                
                let zRotation = simd_quaternion(-Float.pi / 2, simd_float3(0, 0, 1))
                let xRotation = simd_quaternion(Float.pi / 2, simd_float3(1, 0, 0))
                
                att.transform.rotation = xRotation * zRotation
                //att.transform.rotation = zRotation

                anchor.addChild(att)
            }
            
        } attachments: {
            Attachment(id: "hand_label") {
                ImmersiveControls(communicator: $noodles_state).environment(current_doc_method_list)
                
            }
        } .installGestures()
    }
    
    func frame_all() {
        auto_extent = true
        
        noodles_state?.world.frame_all(target_volume: SIMD3<Float>(2,1,2))
    }
}



@MainActor
class ImageTrackingViewModel: ObservableObject {
    private let session = ARKitSession()
    public var root_entity : Entity?
    private let imageInfo = ImageTrackingProvider(
        referenceImages: ReferenceImage.loadReferenceImages(inGroupNamed: "TrackingImages")
    )
    
    var entityMap: [UUID: Entity] = [:]
    
    func start() async {
        do {
            if ImageTrackingProvider.isSupported {
                print("ARKitSession starting.")
                Task {
                    try await session.run([imageInfo])
                    for await update in imageInfo.anchorUpdates {
                        await update_image(update.anchor)
                    }
                }
            }
        }
    }
    
    func update_image(_ anchor: ImageAnchor) async {
        // at the moment, we only work with ONE. Eventually we will figure this out.
        let description = anchor.id
        
        if entityMap[description] == nil {
            // Add a new entity to represent this image.
            print("adding new image")
            
            if let new_entity = try? await Entity(named: "LocationIndicator", in: realityKitContentBundle) {
                entityMap[description] = new_entity
                
                if let root = self.root_entity {
                    root.addChild(new_entity)
                }
            } else {
                print("Unable to load image graphics")
            }
        }
        
        
        if anchor.isTracked {
            //entityMap[description]?.transform = Transform(matrix: anchor.originFromAnchorTransform)
            print(anchor.description)
            self.root_entity?.transform = Transform(matrix: anchor.originFromAnchorTransform)
        }
    }
}

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

class HandInfo {
    var skeleton: HandSkeleton?
    var tf : simd_float4x4 = matrix_identity_float4x4
    var entity : Entity = Entity()
    var enabled = false
}

struct NooImmersiveView: View {
    var new_noodles_config : NewNoodles!
    
    @State private var noodles_state : NoodlesCommunicator?
    @State private var noodles_world : NoodlesWorld?
    @State private var is_bad_host = false
    
    @State private var global_scale = 1.0
    @State private var auto_extent = false
    
    @State private var current_scene : RealityViewContent!
    @State private var current_doc_method_list = MethodListObservable()
    
    @State var ar_session = ARKitSession()
    
    @State var hands : [HandInfo] = [HandInfo(), HandInfo()]
    
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @Environment(\.dismissImmersiveSpace) private var dismissImmersiveSpace
    
    init(new: NewNoodles) {
        new_noodles_config = new
    }
    
    var body: some View {
        RealityView { content, attachments in
            self.current_scene = content
            
            let u = URL(string: new_noodles_config.hostname) ?? URL(string: "ws://localhost:50000")!
            
            noodles_world = NoodlesWorld(content, current_doc_method_list, initial_offset: simd_float3([0, 1, 0]))
            
            noodles_state = NoodlesCommunicator(url: u, world: noodles_world!)
            
            noodles_world?.comm = noodles_state
            
            for h in hands {
                content.add(h.entity)
            }
            
            if let hand_attachment = attachments.entity(for: "hand_label") {
                hand_attachment.position = [0, 0.02, 0]
                hands[0].entity.addChild(hand_attachment)
            }
            
        } update: { content, attachments in
            
//            if !auto_extent{
//                var fv = 1.0
//                if global_scale > 0 {
//                    fv = global_scale
//                } else if global_scale < 0 {
//                    fv = 1.0 / (-global_scale)
//                }
//                let scalar = Float(fv)
//                let root = noodles_state!.world.root_entity
//                var current_tf = root.transform
//                current_tf.scale = [scalar, scalar, scalar]
//                root.move(to: current_tf, relativeTo: root.parent, duration: 1)
//            }
            
            if let hand_attachment = attachments.entity(for: "hand_label") {
                var tf = hands[0].tf;
                
                if let hand_info = hands[0].skeleton {
                    tf *= hand_info.joint(.wrist).anchorFromJointTransform
                }
                
                hands[0].entity.move(to: tf, relativeTo: hand_attachment.parent)
            }
            
        } attachments: {
            Attachment(id: "hand_label") {
//                Button("Stop Immersive") {
//                    Task {
//                        print("Close window for \(new_noodles_config.hostname)")
//                        await dismissImmersiveSpace()
//                    }
//                }
            }
        } .installGestures().task {
            let plane_data = PlaneDetectionProvider(alignments: [.horizontal])
            let hand_data = HandTrackingProvider()
            
            var provider : [DataProvider] = []
            
            if PlaneDetectionProvider.isSupported {
                provider.append(plane_data)
            }
            if HandTrackingProvider.isSupported {
                provider.append(hand_data)
            }
            
            do {
                try await ar_session.run(provider)
                
                Task {
                    for await _ in plane_data.anchorUpdates {
                        //update.anchor.
                    }
                }
                
                Task {
                    for await update in hand_data.anchorUpdates {
                        switch update.anchor.chirality {
                        case .left:
                            if let h = update.anchor.handSkeleton {
                                //print("update left")
                                self.hands[0].skeleton = h
                            }
                            self.hands[0].tf = update.anchor.originFromAnchorTransform
                        case .right:
                            if let h = update.anchor.handSkeleton {
                                self.hands[1].skeleton = h
                            }
                            self.hands[1].tf = update.anchor.originFromAnchorTransform
                        }
                    }
                }
                
                
            } catch {
                print("Unable to use ARKit trackers: \(error)")
            }
        }
    }
    
    func frame_all() {
        auto_extent = true
        
        noodles_state?.world.frame_all(target_volume: SIMD3<Float>(2,1,2))
    }
}

//#Preview(windowStyle: .volumetric) {
//    ContentView(NewNoodles(hostname: ""))
//}

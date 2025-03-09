//
//  SceneReconstruction.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/28/25.
//
import ARKit
import Foundation
import RealityFoundation

@Observable
@MainActor
class SceneReconstructionModel {
    let session = ARKitSession()
    let sceneReconstruction = SceneReconstructionProvider()
    
    var contentRoot = Entity()
    
    private var meshEnities = [UUID: ModelEntity]()
    
    var dataProvidersSupported: Bool {
        SceneReconstructionProvider.isSupported
    }
    
    var ready: Bool {
        sceneReconstruction.state == .initialized
    }
    
    func start() {
        Task {
            if !dataProvidersSupported {
                print("Reconstruction not supported")
                return
            }
            
            if !ready {
                print("Reconstruction not able to start")
                return
            }
            
            try await session.run([sceneReconstruction])
        }
    }
    
    func processReconstruction() async {
        for await update in sceneReconstruction.anchorUpdates {
            let meshAnchor = update.anchor
            
            guard let shape = try? await ShapeResource.generateStaticMesh(from: meshAnchor) else { continue }
            
            print(update.event)
            
            switch update.event {
            case .added:
                let entity = ModelEntity()
                entity.model = await ModelComponent(mesh:.init(shape: shape), materials: [OcclusionMaterial()])
                
                entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                entity.collision = CollisionComponent(shapes: [shape], isStatic: true)
                entity.components.set(InputTargetComponent())
                entity.physicsBody = PhysicsBodyComponent(mode: .static)
                
                meshEnities[meshAnchor.id] = entity
                contentRoot.addChild(entity)
            case .updated:
                guard let entity = meshEnities[meshAnchor.id] else { continue }
                entity.transform = Transform(matrix: meshAnchor.originFromAnchorTransform)
                entity.collision?.shapes = [shape]
            case .removed:
                meshEnities[meshAnchor.id]?.removeFromParent()
                meshEnities[meshAnchor.id] = nil
            }
        }
        
    }
    
    func monitorSessionEvents() async {
        for await event in session.events {
            switch event {
            case .authorizationChanged(type: _, status: let status):
                print("Authorization status changed: \(status)")
                
                if status == .denied {
                    // error?
                }
            case .dataProviderStateChanged(dataProviders: let provider, newState: let newState, error: let error):
                print("Data provider changed state: \(provider), \(newState)")
                //
            @unknown default:
                print("Unknown event \(event)")
            }
        }
    }
}

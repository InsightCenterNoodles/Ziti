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
    let session = ARKitManager.shared
    
    var contentRoot = Entity()
    
    private var meshEnities = [UUID: ModelEntity]()
    
    func start() {
        session.start()
    }
    
    func processReconstruction() async {
        for await update in session.sceneReconstruction.anchorUpdates {
            let meshAnchor = update.anchor
            
            guard let shape = try? await ShapeResource.generateStaticMesh(from: meshAnchor) else { continue }
            
            //print(update.event)
            
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
}

//
//  MeshGeneration.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/12/24.
//

import Foundation
import RealityKit


struct MeshGeneration {
    func build_simple_mesh() -> ModelEntity {
        let positions: [SIMD3<Float>] = [[-0.25, -0.25, 0], [0.25, -0.25, 0], [0, 0.25, 0], .zero]
        
        var description = MeshDescriptor(name: "Generated Mesh")
        description.positions = MeshBuffers.Positions(positions[0...2])
        description.primitives = .triangles([0,1,2])
        
        var tri_mat = PhysicallyBasedMaterial()
        tri_mat.baseColor = PhysicallyBasedMaterial.BaseColor.init(tint: .white)
        
        let generated_model = ModelEntity(mesh: try! .generate(from: [description]), materials: [tri_mat])
        
        return generated_model
    }
}

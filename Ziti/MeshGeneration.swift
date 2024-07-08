//
//  MeshGeneration.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/12/24.
//

import Foundation
import RealityKit
import Metal


let SPHERE_POS : [SIMD3<Float>] = [
    [0.000000, -1.000000, 0.000000],
    [0.723607, -0.447220, 0.525725],
    [-0.276388, -0.447220, 0.850649],
    [-0.894426, -0.447216, 0.000000],
    [-0.276388, -0.447220, -0.850649],
    [0.723607, -0.447220, -0.525725],
    [0.276388, 0.447220, 0.850649],
    [-0.723607, 0.447220, 0.525725],
    [-0.723607, 0.447220, -0.525725],
    [0.276388, 0.447220, -0.850649],
    [0.894426, 0.447216, 0.000000],
    [0.000000, 1.000000, 0.000000],
    [-0.232822, -0.657519, 0.716563],
    [-0.162456, -0.850654, 0.499995],
    [-0.077607, -0.967950, 0.238853],
    [0.203181, -0.967950, 0.147618],
    [0.425323, -0.850654, 0.309011],
    [0.609547, -0.657519, 0.442856],
    [0.531941, -0.502302, 0.681712],
    [0.262869, -0.525738, 0.809012],
    [-0.029639, -0.502302, 0.864184],
    [0.812729, -0.502301, -0.295238],
    [0.850648, -0.525736, 0.000000],
    [0.812729, -0.502301, 0.295238],
    [0.203181, -0.967950, -0.147618],
    [0.425323, -0.850654, -0.309011],
    [0.609547, -0.657519, -0.442856],
    [-0.753442, -0.657515, 0.000000],
    [-0.525730, -0.850652, 0.000000],
    [-0.251147, -0.967949, 0.000000],
    [-0.483971, -0.502302, 0.716565],
    [-0.688189, -0.525736, 0.499997],
    [-0.831051, -0.502299, 0.238853],
    [-0.232822, -0.657519, -0.716563],
    [-0.162456, -0.850654, -0.499995],
    [-0.077607, -0.967950, -0.238853],
    [-0.831051, -0.502299, -0.238853],
    [-0.688189, -0.525736, -0.499997],
    [-0.483971, -0.502302, -0.716565],
    [-0.029639, -0.502302, -0.864184],
    [0.262869, -0.525738, -0.809012],
    [0.531941, -0.502302, -0.681712],
    [0.956626, 0.251149, 0.147618],
    [0.951058, -0.000000, 0.309013],
    [0.860698, -0.251151, 0.442858],
    [0.860698, -0.251151, -0.442858],
    [0.951058, 0.000000, -0.309013],
    [0.956626, 0.251149, -0.147618],
    [0.155215, 0.251152, 0.955422],
    [0.000000, -0.000000, 1.000000],
    [-0.155215, -0.251152, 0.955422],
    [0.687159, -0.251152, 0.681715],
    [0.587786, 0.000000, 0.809017],
    [0.436007, 0.251152, 0.864188],
    [-0.860698, 0.251151, 0.442858],
    [-0.951058, -0.000000, 0.309013],
    [-0.956626, -0.251149, 0.147618],
    [-0.436007, -0.251152, 0.864188],
    [-0.587786, 0.000000, 0.809017],
    [-0.687159, 0.251152, 0.681715],
    [-0.687159, 0.251152, -0.681715],
    [-0.587786, -0.000000, -0.809017],
    [-0.436007, -0.251152, -0.864188],
    [-0.956626, -0.251149, -0.147618],
    [-0.951058, 0.000000, -0.309013],
    [-0.860698, 0.251151, -0.442858],
    [0.436007, 0.251152, -0.864188],
    [0.587786, -0.000000, -0.809017],
    [0.687159, -0.251152, -0.681715],
    [-0.155215, -0.251152, -0.955422],
    [0.000000, 0.000000, -1.000000],
    [0.155215, 0.251152, -0.955422],
    [0.831051, 0.502299, 0.238853],
    [0.688189, 0.525736, 0.499997],
    [0.483971, 0.502302, 0.716565],
    [0.029639, 0.502302, 0.864184],
    [-0.262869, 0.525738, 0.809012],
    [-0.531941, 0.502302, 0.681712],
    [-0.812729, 0.502301, 0.295238],
    [-0.850648, 0.525736, 0.000000],
    [-0.812729, 0.502301, -0.295238],
    [-0.531941, 0.502302, -0.681712],
    [-0.262869, 0.525738, -0.809012],
    [0.029639, 0.502302, -0.864184],
    [0.483971, 0.502302, -0.716565],
    [0.688189, 0.525736, -0.499997],
    [0.831051, 0.502299, -0.238853],
    [0.077607, 0.967950, 0.238853],
    [0.162456, 0.850654, 0.499995],
    [0.232822, 0.657519, 0.716563],
    [0.753442, 0.657515, 0.000000],
    [0.525730, 0.850652, 0.000000],
    [0.251147, 0.967949, 0.000000],
    [-0.203181, 0.967950, 0.147618],
    [-0.425323, 0.850654, 0.309011],
    [-0.609547, 0.657519, 0.442856],
    [-0.203181, 0.967950, -0.147618],
    [-0.425323, 0.850654, -0.309011],
    [-0.609547, 0.657519, -0.442856],
    [0.077607, 0.967950, -0.238853],
    [0.162456, 0.850654, -0.499995],
    [0.232822, 0.657519, -0.716563],
    [0.361800, 0.894429, -0.262863],
    [0.638194, 0.723610, -0.262864],
    [0.447209, 0.723612, -0.525728],
    [-0.138197, 0.894430, -0.425319],
    [-0.052790, 0.723612, -0.688185],
    [-0.361804, 0.723612, -0.587778],
    [-0.447210, 0.894429, 0.000000],
    [-0.670817, 0.723611, -0.162457],
    [-0.670817, 0.723611, 0.162457],
    [-0.138197, 0.894430, 0.425319],
    [-0.361804, 0.723612, 0.587778],
    [-0.052790, 0.723612, 0.688185],
    [0.361800, 0.894429, 0.262863],
    [0.447209, 0.723612, 0.525728],
    [0.638194, 0.723610, 0.262864],
    [0.861804, 0.276396, -0.425322],
    [0.809019, 0.000000, -0.587782],
    [0.670821, 0.276397, -0.688189],
    [-0.138199, 0.276397, -0.951055],
    [-0.309016, -0.000000, -0.951057],
    [-0.447215, 0.276397, -0.850649],
    [-0.947213, 0.276396, -0.162458],
    [-1.000000, 0.000001, 0.000000],
    [-0.947213, 0.276397, 0.162458],
    [-0.447216, 0.276397, 0.850648],
    [-0.309017, -0.000001, 0.951056],
    [-0.138199, 0.276397, 0.951055],
    [0.670820, 0.276396, 0.688190],
    [0.809019, -0.000002, 0.587783],
    [0.861804, 0.276394, 0.425323],
    [0.309017, -0.000000, -0.951056],
    [0.447216, -0.276398, -0.850648],
    [0.138199, -0.276398, -0.951055],
    [-0.809018, -0.000000, -0.587783],
    [-0.670819, -0.276397, -0.688191],
    [-0.861803, -0.276396, -0.425324],
    [-0.809018, 0.000000, 0.587783],
    [-0.861803, -0.276396, 0.425324],
    [-0.670819, -0.276397, 0.688191],
    [0.309017, 0.000000, 0.951056],
    [0.138199, -0.276398, 0.951055],
    [0.447216, -0.276398, 0.850648],
    [1.000000, 0.000000, 0.000000],
    [0.947213, -0.276396, 0.162458],
    [0.947213, -0.276396, -0.162458],
    [0.361803, -0.723612, -0.587779],
    [0.138197, -0.894429, -0.425321],
    [0.052789, -0.723611, -0.688186],
    [-0.447211, -0.723612, -0.525727],
    [-0.361801, -0.894429, -0.262863],
    [-0.638195, -0.723609, -0.262863],
    [-0.638195, -0.723609, 0.262864],
    [-0.361801, -0.894428, 0.262864],
    [-0.447211, -0.723610, 0.525729],
    [0.670817, -0.723611, -0.162457],
    [0.670818, -0.723610, 0.162458],
    [0.447211, -0.894428, 0.000001],
    [0.052790, -0.723612, 0.688185],
    [0.138199, -0.894429, 0.425321],
    [0.361805, -0.723611, 0.587779],
    .zero
];

let SPHERE_INDEX : [[UInt32]] = [
    [0, 15, 14],
    [1, 17, 23],
    [0, 14, 29],
    [0, 29, 35],
    [0, 35, 24],
    [1, 23, 44],
    [2, 20, 50],
    [3, 32, 56],
    [4, 38, 62],
    [5, 41, 68],
    [1, 44, 51],
    [2, 50, 57],
    [3, 56, 63],
    [4, 62, 69],
    [5, 68, 45],
    [6, 74, 89],
    [7, 77, 95],
    [8, 80, 98],
    [9, 83, 101],
    [10, 86, 90],
    [92, 99, 11],
    [91, 102, 92],
    [90, 103, 91],
    [92, 102, 99],
    [102, 100, 99],
    [91, 103, 102],
    [103, 104, 102],
    [102, 104, 100],
    [104, 101, 100],
    [90, 86, 103],
    [86, 85, 103],
    [103, 85, 104],
    [85, 84, 104],
    [104, 84, 101],
    [84, 9, 101],
    [99, 96, 11],
    [100, 105, 99],
    [101, 106, 100],
    [99, 105, 96],
    [105, 97, 96],
    [100, 106, 105],
    [106, 107, 105],
    [105, 107, 97],
    [107, 98, 97],
    [101, 83, 106],
    [83, 82, 106],
    [106, 82, 107],
    [82, 81, 107],
    [107, 81, 98],
    [81, 8, 98],
    [96, 93, 11],
    [97, 108, 96],
    [98, 109, 97],
    [96, 108, 93],
    [108, 94, 93],
    [97, 109, 108],
    [109, 110, 108],
    [108, 110, 94],
    [110, 95, 94],
    [98, 80, 109],
    [80, 79, 109],
    [109, 79, 110],
    [79, 78, 110],
    [110, 78, 95],
    [78, 7, 95],
    [93, 87, 11],
    [94, 111, 93],
    [95, 112, 94],
    [93, 111, 87],
    [111, 88, 87],
    [94, 112, 111],
    [112, 113, 111],
    [111, 113, 88],
    [113, 89, 88],
    [95, 77, 112],
    [77, 76, 112],
    [112, 76, 113],
    [76, 75, 113],
    [113, 75, 89],
    [75, 6, 89],
    [87, 92, 11],
    [88, 114, 87],
    [89, 115, 88],
    [87, 114, 92],
    [114, 91, 92],
    [88, 115, 114],
    [115, 116, 114],
    [114, 116, 91],
    [116, 90, 91],
    [89, 74, 115],
    [74, 73, 115],
    [115, 73, 116],
    [73, 72, 116],
    [116, 72, 90],
    [72, 10, 90],
    [47, 86, 10],
    [46, 117, 47],
    [45, 118, 46],
    [47, 117, 86],
    [117, 85, 86],
    [46, 118, 117],
    [118, 119, 117],
    [117, 119, 85],
    [119, 84, 85],
    [45, 68, 118],
    [68, 67, 118],
    [118, 67, 119],
    [67, 66, 119],
    [119, 66, 84],
    [66, 9, 84],
    [71, 83, 9],
    [70, 120, 71],
    [69, 121, 70],
    [71, 120, 83],
    [120, 82, 83],
    [70, 121, 120],
    [121, 122, 120],
    [120, 122, 82],
    [122, 81, 82],
    [69, 62, 121],
    [62, 61, 121],
    [121, 61, 122],
    [61, 60, 122],
    [122, 60, 81],
    [60, 8, 81],
    [65, 80, 8],
    [64, 123, 65],
    [63, 124, 64],
    [65, 123, 80],
    [123, 79, 80],
    [64, 124, 123],
    [124, 125, 123],
    [123, 125, 79],
    [125, 78, 79],
    [63, 56, 124],
    [56, 55, 124],
    [124, 55, 125],
    [55, 54, 125],
    [125, 54, 78],
    [54, 7, 78],
    [59, 77, 7],
    [58, 126, 59],
    [57, 127, 58],
    [59, 126, 77],
    [126, 76, 77],
    [58, 127, 126],
    [127, 128, 126],
    [126, 128, 76],
    [128, 75, 76],
    [57, 50, 127],
    [50, 49, 127],
    [127, 49, 128],
    [49, 48, 128],
    [128, 48, 75],
    [48, 6, 75],
    [53, 74, 6],
    [52, 129, 53],
    [51, 130, 52],
    [53, 129, 74],
    [129, 73, 74],
    [52, 130, 129],
    [130, 131, 129],
    [129, 131, 73],
    [131, 72, 73],
    [51, 44, 130],
    [44, 43, 130],
    [130, 43, 131],
    [43, 42, 131],
    [131, 42, 72],
    [42, 10, 72],
    [66, 71, 9],
    [67, 132, 66],
    [68, 133, 67],
    [66, 132, 71],
    [132, 70, 71],
    [67, 133, 132],
    [133, 134, 132],
    [132, 134, 70],
    [134, 69, 70],
    [68, 41, 133],
    [41, 40, 133],
    [133, 40, 134],
    [40, 39, 134],
    [134, 39, 69],
    [39, 4, 69],
    [60, 65, 8],
    [61, 135, 60],
    [62, 136, 61],
    [60, 135, 65],
    [135, 64, 65],
    [61, 136, 135],
    [136, 137, 135],
    [135, 137, 64],
    [137, 63, 64],
    [62, 38, 136],
    [38, 37, 136],
    [136, 37, 137],
    [37, 36, 137],
    [137, 36, 63],
    [36, 3, 63],
    [54, 59, 7],
    [55, 138, 54],
    [56, 139, 55],
    [54, 138, 59],
    [138, 58, 59],
    [55, 139, 138],
    [139, 140, 138],
    [138, 140, 58],
    [140, 57, 58],
    [56, 32, 139],
    [32, 31, 139],
    [139, 31, 140],
    [31, 30, 140],
    [140, 30, 57],
    [30, 2, 57],
    [48, 53, 6],
    [49, 141, 48],
    [50, 142, 49],
    [48, 141, 53],
    [141, 52, 53],
    [49, 142, 141],
    [142, 143, 141],
    [141, 143, 52],
    [143, 51, 52],
    [50, 20, 142],
    [20, 19, 142],
    [142, 19, 143],
    [19, 18, 143],
    [143, 18, 51],
    [18, 1, 51],
    [42, 47, 10],
    [43, 144, 42],
    [44, 145, 43],
    [42, 144, 47],
    [144, 46, 47],
    [43, 145, 144],
    [145, 146, 144],
    [144, 146, 46],
    [146, 45, 46],
    [44, 23, 145],
    [23, 22, 145],
    [145, 22, 146],
    [22, 21, 146],
    [146, 21, 45],
    [21, 5, 45],
    [26, 41, 5],
    [25, 147, 26],
    [24, 148, 25],
    [26, 147, 41],
    [147, 40, 41],
    [25, 148, 147],
    [148, 149, 147],
    [147, 149, 40],
    [149, 39, 40],
    [24, 35, 148],
    [35, 34, 148],
    [148, 34, 149],
    [34, 33, 149],
    [149, 33, 39],
    [33, 4, 39],
    [33, 38, 4],
    [34, 150, 33],
    [35, 151, 34],
    [33, 150, 38],
    [150, 37, 38],
    [34, 151, 150],
    [151, 152, 150],
    [150, 152, 37],
    [152, 36, 37],
    [35, 29, 151],
    [29, 28, 151],
    [151, 28, 152],
    [28, 27, 152],
    [152, 27, 36],
    [27, 3, 36],
    [27, 32, 3],
    [28, 153, 27],
    [29, 154, 28],
    [27, 153, 32],
    [153, 31, 32],
    [28, 154, 153],
    [154, 155, 153],
    [153, 155, 31],
    [155, 30, 31],
    [29, 14, 154],
    [14, 13, 154],
    [154, 13, 155],
    [13, 12, 155],
    [155, 12, 30],
    [12, 2, 30],
    [21, 26, 5],
    [22, 156, 21],
    [23, 157, 22],
    [21, 156, 26],
    [156, 25, 26],
    [22, 157, 156],
    [157, 158, 156],
    [156, 158, 25],
    [158, 24, 25],
    [23, 17, 157],
    [17, 16, 157],
    [157, 16, 158],
    [16, 15, 158],
    [158, 15, 24],
    [15, 0, 24],
    [12, 20, 2],
    [13, 159, 12],
    [14, 160, 13],
    [12, 159, 20],
    [159, 19, 20],
    [13, 160, 159],
    [160, 161, 159],
    [159, 161, 19],
    [161, 18, 19],
    [14, 15, 160],
    [15, 16, 160],
    [160, 16, 161],
    [16, 17, 161],
    [161, 17, 18],
    [17, 1, 18],
];

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
    
    static func build_sphere() -> ModelEntity {
        let positions = SPHERE_POS.map {
            p in
            p * 0.05
        }
        
        var indicies = [UInt32]()
        
        indicies.reserveCapacity(SPHERE_INDEX.count * 3)
        
        for f in SPHERE_INDEX {
            indicies.append(contentsOf: f)
        }
        
        var description = MeshDescriptor(name: "Root Mesh")
        description.positions = MeshBuffers.Positions(positions)
        description.normals = MeshBuffers.Normals(SPHERE_POS)
        description.primitives = .triangles(indicies)
        
        var tri_mat = PhysicallyBasedMaterial()
        tri_mat.baseColor = PhysicallyBasedMaterial.BaseColor.init(tint: .opaqueSeparator)
        tri_mat.clearcoat = PhysicallyBasedMaterial.Clearcoat(floatLiteral: 1.0)
        tri_mat.roughness = PhysicallyBasedMaterial.Roughness(floatLiteral: 0.0)
        tri_mat.metallic  = PhysicallyBasedMaterial.Metallic(floatLiteral: 1.0)
        
        return ModelEntity(mesh: try! .generate(from: [description]), materials: [tri_mat])
    }
}

private func determine_low_level_semantic(attribute: GeomAttrib) -> LowLevelMesh.VertexSemantic? {
    switch attribute.semantic {
    case "POSITION":
        return LowLevelMesh.VertexSemantic.position;
    case "NORMAL":
        return LowLevelMesh.VertexSemantic.normal;
    case "TEXTURE":
        let lookup = [
            LowLevelMesh.VertexSemantic.uv0,
            LowLevelMesh.VertexSemantic.uv1,
            LowLevelMesh.VertexSemantic.uv2,
            LowLevelMesh.VertexSemantic.uv3,
            LowLevelMesh.VertexSemantic.uv4,
        ]
        return lookup[Int(attribute.channel)]
    case "TANGENT":
        return LowLevelMesh.VertexSemantic.tangent
    default:
        return nil
    }
    
}

private func determine_low_level_format(attribute: GeomAttrib) -> MTLVertexFormat? {
    // only looking for valid formats for each type
    
    switch attribute.semantic {
    case "POSITION", "NORMAL", "TANGENT":
        if attribute.format == "VEC3" {
            return .float3
        }
    case "TEXTURE":
        switch attribute.format {
        case "VEC2":
            return .float2
        case "U16VEC2":
            return .ushort2Normalized
        default:
            return nil
        }
    default:
        return nil
    }
    return nil
}

func determine_bounding_box(attribute: GeomAttrib,
                            vertex_count: Int,
                            world: NoodlesWorld) -> BoundingBox {
     
    if attribute.maximum_value.count > 2 && attribute.minimum_value.count > 2 {
        let min_bb = SIMD3<Float>(
            x: attribute.minimum_value[0],
            y: attribute.minimum_value[1],
            z: attribute.minimum_value[2]
        )
        
        let max_bb = SIMD3<Float>(
            x: attribute.maximum_value[0],
            y: attribute.maximum_value[1],
            z: attribute.maximum_value[2]
        )
        
        return BoundingBox(min: min_bb, max: max_bb)
    }
    
    let buffer_view = world.buffer_view_list.get(attribute.view)!
    
    let data = buffer_view.get_slice(offset: attribute.offset);
    
    var min_bb = SIMD3<Float>(repeating: Float32.greatestFiniteMagnitude)
    var max_bb = SIMD3<Float>(repeating: -Float32.greatestFiniteMagnitude)
    
    let actual_stride = max(attribute.stride, 3*4)
    
    data.withUnsafeBytes { ptr in
        
        for p_i in 0 ..< vertex_count {
            let delta = Int(actual_stride) * p_i
            
            let l_bb = SIMD3<Float>(
                x: ptr.loadUnaligned(fromByteOffset: delta, as: Float32.self),
                y: ptr.loadUnaligned(fromByteOffset: delta + 4, as: Float32.self),
                z: ptr.loadUnaligned(fromByteOffset: delta + 8, as: Float32.self)
            )
            
            min_bb = pointwiseMin(min_bb, l_bb)
            max_bb = pointwiseMax(max_bb, l_bb)
        }
    }
    
    return BoundingBox(min: min_bb, max: max_bb)
}

func determine_index_type(patch: GeomPatch) -> MTLPrimitiveType? {
    switch patch.type {
    case "POINTS":
        return .point
    case "LINES":
        return .line
    case "LINE_STRIP":
        return .lineStrip
    case "TRIANGLES":
        return .triangle
    case "TRIANGLE_STRIP":
        return .triangleStrip
    default:
        return nil
    }
}

func format_to_stride(format_str: String) -> Int64 {
    switch format_str {
    case "U8": return 1
    case "U16": return 2
    case "U32": return 4
        
    case "U8VEC4": return 4
        
    case "U16VEC2" : return 4
        
    case "VEC2": return 2 * 4
    case "VEC3": return 3 * 4
    case "VEC4": return 4 * 4
        
    case "MAT3": return 3 * 3 * 4
    case "MAT4": return 4 * 4 * 4
    default:
        return 1
    }
}

func patch_to_low_level_mesh(patch: GeomPatch,
                             world: NoodlesWorld) -> LowLevelMesh? {
    dump(patch)
    // these have format, layout index, offset from start of vertex data, and semantic
    var ll_attribs = [LowLevelMesh.Attribute]()
    
    // these have the buffer index, an offset to the first byte in this buffer, and a stride
    var ll_layouts = [LowLevelMesh.Layout]()
    
    // we need to pack all buffer references into the layout list
    
    struct LayoutPack : Hashable {
        let view_id : NooID
        let buffer_offset : Int64
        let buffer_stride : Int64
    }
    
    var layout_mapping = [LayoutPack : Int]();
    
    var position_bb: BoundingBox?;
    
    for attribute in patch.attributes {
        let buffer_view = world.buffer_view_list.get(attribute.view)!
        let actual_stride = max(attribute.stride, format_to_stride(format_str: attribute.format))
        //let buffer = info.buffer_cache[buffer_view.source_buffer.slot]!
        
        // - attribute.view    this is essentially which buffer we are using
        // - attribute.offset  this is the offset to the buffer
        // - attribute.stride  this is the offset between attributes info
        
        //
        let key = LayoutPack(view_id: attribute.view,
                             buffer_offset: buffer_view.info.offset,
                             buffer_stride: actual_stride);
        
        guard let ll_semantic = determine_low_level_semantic(attribute: attribute) else {
            continue;
        }
        
        guard let ll_format = determine_low_level_format(attribute: attribute) else {
            continue;
        }
        
        if ll_semantic == .position {
            position_bb = determine_bounding_box(attribute: attribute, vertex_count: Int(patch.vertex_count), world: world)
        }
        
        let layout_index = {
            if let layout_index = layout_mapping[key] {
                return layout_index
            } else {
                let layout_index = ll_layouts.count
                layout_mapping[key] = layout_index
                ll_layouts.append(LowLevelMesh.Layout(bufferIndex: layout_index,  // is this correct?
                                                      bufferOffset: Int(key.buffer_offset),
                                                      bufferStride: Int(key.buffer_stride)))
                //print("ADDING LAYOUT \(key) at index \(layout_index)")
                return layout_index
            }
        }()
        
        ll_attribs.append(LowLevelMesh.Attribute(semantic: ll_semantic, format: ll_format, layoutIndex: layout_index, offset: Int(attribute.offset)))
        
    }
    
    // if we dont have a bounding box, we never had a position attrib
    
    guard let resolved_bb = position_bb else {
        return nil
    }
    
    ll_layouts.reserveCapacity(layout_mapping.count)
    
    let format = patch.indices?.format ?? "U32"
    var index_type : MTLIndexType
    
    switch format {
    case "U16":
        index_type = .uint16
    case "U32":
        index_type = .uint32
    default:
        return nil
    }
    
    
    let meshDescriptor = LowLevelMesh.Descriptor(vertexCapacity: Int(patch.vertex_count),
                                                 vertexAttributes: ll_attribs,
                                                 vertexLayouts: ll_layouts,
                                                 indexCapacity: Int(patch.indices?.count ?? 0),
                                                 indexType: index_type)
    
    let lowLevelMesh : LowLevelMesh;
    
    do {
        // this might need to be on the main thread?
        lowLevelMesh = try LowLevelMesh(descriptor: meshDescriptor)
    } catch {
        print("Explosion in mesh generation \(error)")
        return nil
    }
    
    
    // now execute uploads
    
    for (k,v) in layout_mapping {
        let buffer_view = world.buffer_view_list.get(k.view_id)!
        //let buffer = buffer_view.buffer!
        
        let slice = buffer_view.get_slice(offset: 0)
        lowLevelMesh.replaceUnsafeMutableBytes(bufferIndex: v, { ptr in
            //print("Uploading mesh data \(ptr.count)")
            let _ = slice.copyBytes(to: ptr)
            //print("Uploaded \(res)")
        })
    }
    
    if let index_info = patch.indices {
        
        let buffer_view = world.buffer_view_list.get(index_info.view)!
        
        let bytes = buffer_view.get_slice(offset: index_info.offset)
        
        lowLevelMesh.replaceUnsafeMutableIndices { ptr in
            //print("Uploading index data \(ptr.count)")
            let _ = bytes.copyBytes(to: ptr)
            //print("Uploaded \(res)")
        }
        
        guard let index_type = determine_index_type(patch: patch) else {
            return nil
        }
        
        //print("Installing index part \(index_type) bb: \(resolved_bb)")
        
        lowLevelMesh.parts.replaceAll([
            .init(indexOffset: 0, indexCount: Int(index_info.count), topology: index_type, materialIndex: 0, bounds: resolved_bb)
        ])
    }
    
    
    
//    var context = ComputeContext.shared
//    var pipe_state = try? context.device.makeComputePipelineState(function: context.direct_upload_function)
//    
//    var cbuffer = context.command_queue.makeCommandBuffer()!
//    var cencoder = cbuffer.makeComputeCommandEncoder()!
//
    
    return lowLevelMesh
}

//
//  NoodlesWorld.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/16/24.
//

import Foundation
import SwiftUI
import RealityKit
import RealityKitContent

protocol NoodlesComponent {
    func create(world: NoodlesWorld);
}

class NooBuffer : NoodlesComponent {
    var info: MsgBufferCreate
    
    init(msg: MsgBufferCreate) {
        info = msg
    }
    
    func create(world: NoodlesWorld) {
        print("Created buffer")
    }
}

class NooBufferView : NoodlesComponent {
    var info: MsgBufferViewCreate
    
    var buffer: NooBuffer!
    
    init(msg: MsgBufferViewCreate) {
        info = msg
    }
    
    func create(world: NoodlesWorld) {
        buffer = world.buffer_list.get(info.source_buffer)!;
        print("Created buffer view")
    }
    
    func get_slice(offset: Int64) -> Data {
        // get the orig ending
        let ending = info.offset + info.length
        let total_offset = info.offset + offset
        return buffer.info.bytes[total_offset ..< ending]
    }
    
    func get_slice(offset: Int64, length: Int64) -> Data {
        let total_offset = info.offset + offset
        let ending = total_offset + length
        return buffer.info.bytes[total_offset ..< ending]
    }
}

class NooMaterial : NoodlesComponent {
    var info: MsgMaterialCreate
    
    var mat : (any RealityKit.Material)!
    
    init(msg: MsgMaterialCreate) {
        info = msg
    }
    
    func create(world: NoodlesWorld) {
        
        var tri_mat = PhysicallyBasedMaterial()
        tri_mat.baseColor = PhysicallyBasedMaterial.BaseColor.init(tint: info.pbr_info.base_color)
        tri_mat.roughness = PhysicallyBasedMaterial.Roughness(floatLiteral: info.pbr_info.roughness)
        tri_mat.metallic = PhysicallyBasedMaterial.Metallic(floatLiteral: info.pbr_info.metallic)
        
        mat = tri_mat
        
        print("Created material")
    }
}

class NooGeometry : NoodlesComponent {
    var info: MsgGeometryCreate
    
    var mesh_resources: [MeshResource] = []
    var mesh_materials: [any RealityKit.Material] = []
    
    init(msg: MsgGeometryCreate) {
        info = msg
    }
    
    func create(world: NoodlesWorld) {
        for patch in info.patches {
            add_patch(patch, world)
        }
        print("Created geometry")
    }
    
    func add_patch(_ patch: GeomPatch, _ world: NoodlesWorld) {
        var description = MeshDescriptor()
        
        for attrib in patch.attributes {
            let buffer_view = world.buffer_view_list.get(attrib.view)!
            let slice = buffer_view.get_slice(offset: attrib.offset)
            
            switch attrib.semantic {
            case "POSITION":
                let attrib_data = realize_vec3(slice, VAttribFormat.V3, vcount: Int(patch.vertex_count), stride: Int(attrib.stride))
                description.positions = MeshBuffers.Positions(attrib_data);
                
            default:
                print("Not handling attribute \(attrib.semantic)")
                break;
            }
        }
        
        
        if let idx = patch.indices {
            let buffer_view = world.buffer_view_list.get(idx.view)!
            let idx_list = realize_index(buffer_view, idx)
            description.primitives = .triangles(idx_list)
        }
        
        if let mat = world.material_list.get(patch.material) {
            mesh_materials.append( mat.mat )
        } else {
            var tri_mat = PhysicallyBasedMaterial()
            tri_mat.baseColor = PhysicallyBasedMaterial.BaseColor.init(tint: .white)
            mesh_materials.append( tri_mat )
        }
        
        mesh_resources.append( try! .generate(from: [description]) )
        
    }
}

class NooEntity : NoodlesComponent {
    var info: MsgEntityCreate
    
    var entity: Entity
    
    var sub_entities: [Entity]
    
    init(msg: MsgEntityCreate) {
        info = msg
        entity = Entity()
        sub_entities = []
    }
    
    func create(world: NoodlesWorld) {
        // TODO: Needs remove
        world.scene.add(entity)
        
        if info.parent.is_valid() {
            let parent_ent = world.entity_list.get(info.parent)!
            parent_ent.entity.addChild(entity)
        } else {
            world.root_entity.addChild(entity)
        }
        
        if let g = info.rep {
            set_representation(g, world)
        }
        
        print("Created entity")
    }
    
    func set_representation(_ rep: RenderRep, _ world: NoodlesWorld) {
        for sub_entity in sub_entities {
            world.scene.remove(sub_entity)
        }
        sub_entities.removeAll(keepingCapacity: true)
        
        guard let geom = world.geometry_list.get(rep.mesh) else {
            print("Unable to find geometry")
            return
        }
        
        for (mat, mesh) in zip(geom.mesh_materials, geom.mesh_resources) {
            let new_entity = ModelEntity(mesh: mesh, materials: [mat])
            
            world.scene.add(new_entity)
            
            sub_entities.append(new_entity)
            
            entity.addChild(new_entity)
        }
    }
    
    func update(world: NoodlesWorld, _ update: MsgEntityUpdate) {
        
    }
}

enum VAttribFormat {
    case V2
    case V3
}

extension VAttribFormat {
    func byte_size() -> Int {
        switch self {
        case .V2:
            return 2 * 4
        case .V3:
            return 3 * 4
        }
    }
}

func realize_vec3(_ data: Data, _ fmt: VAttribFormat, vcount: Int, stride: Int) -> [SIMD3<Float>] {
    if fmt != VAttribFormat.V3 {
        print("No conversions for vformats yet!");
        return []
    }
    
    let true_stride = max(stride, fmt.byte_size())
    
    return data.withUnsafeBytes {
        (pointer: UnsafeRawBufferPointer) -> [SIMD3<Float>] in
        
        var ret : [SIMD3<Float>] = []
        
        ret.reserveCapacity(vcount)
        
        for vertex_i in 0 ..< vcount {
            let place = vertex_i * true_stride
            ret.append( pointer.loadUnaligned(fromByteOffset: place, as: SIMD3<Float>.self) )
        }
        
        return ret
    }
}

func realize_index(_ buffer_view: NooBufferView, _ idx: GeomIndex) -> [UInt32] {
    if idx.stride != 0 {
        fatalError("Unable to handle strided index buffers")
    }
    
    let byte_count : Int64;
    switch idx.format {
    case "U8":
        byte_count = idx.count
    case "U16":
        byte_count = idx.count*2
    case "U32":
        byte_count = idx.count*4
    default:
        fatalError("unknown index format")
    }
    
    // TODO: there is something weird here
    
    let slice = buffer_view.get_slice(offset: idx.offset, length: byte_count)
    
    return slice.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> [UInt32] in
        
        switch idx.format {
        case "U8":
            let arr = pointer.bindMemory(to: UInt8.self)
            return Array<UInt8>(arr).map { UInt32($0) }
            
        case "U16":
            let arr = pointer.bindMemory(to: UInt16.self)
            return Array<UInt16>(arr).map { UInt32($0) }

        case "U32":
            let arr = pointer.bindMemory(to: UInt32.self)
            return Array<UInt32>(arr)
            
        default:
            fatalError("unknown index format")
        }
    }
}

class ComponentList<T: NoodlesComponent> {
    var list : Dictionary<UInt32, T> = [:]
    
    func set(_ id: NooID, _ val : T, _ world: NoodlesWorld) {
        assert(id.is_valid())
        list[id.slot] = val
        val.create(world: world)
    }
    
    func get(_ id: NooID) -> T? {
        return list[id.slot]
    }
    
    func erase(_ id: NooID) {
        list.removeValue(forKey: id.slot)
    }
}

class NoodlesWorld {
    var scene : RealityViewContent;
    
    //public var methods_list = ComponentList<MsgMethodCreate>()
    //public var signals_list = ComponentList<MsgSignalCreate>()
    
    public var entity_list = ComponentList<NooEntity>()
    //public var plot_list = ComponentList<MsgPlotCreate>()
    //public var table_list = ComponentList<MsgTableCreate>()
    
    public var material_list = ComponentList<NooMaterial>()
    
    public var geometry_list = ComponentList<NooGeometry>()
    
    //public var light_list = ComponentList<MsgLightCreate>()
    
    //public var image_list = ComponentList<MsgImageCreate>()
    //public var texture_list = ComponentList<MsgTextureCreate>()
    //public var signal_list = ComponentList<MsgSignalCreate>()
    
    public var buffer_view_list = ComponentList<NooBufferView>()
    public var buffer_list = ComponentList<NooBuffer>()
    
    var root_entity : Entity
    
    init(_ scene: RealityViewContent) {
        self.scene = scene
        
        root_entity = Entity()
        
        scene.add(root_entity)
    }
    
    func handle_message(_ msg: FromServerMessage) {
        switch (msg) {
            
        case .method_create(_):
            //methods_list.set(x.id, x)
            break
        case .method_delete(_):
            break
            
        case .signal_create(_):
            break
        case .signal_delete(_):
            break
            
        case .entity_create(let x):
            let e = NooEntity(msg: x)
            entity_list.set(x.id, e, self)
        case .entity_update(_):
            break
        case .entity_delete(let x):
            entity_list.erase(x.id)
            
        case .plot_create(_):
            break
        case .plot_update(_):
            break
        case .plot_delete(_):
            break
            
        case .buffer_create(let x):
            let e = NooBuffer(msg: x)
            buffer_list.set(x.id, e, self)
        case .buffer_delete(let x):
            buffer_list.erase(x.id)
            
        case .buffer_view_create(let x):
            let e = NooBufferView(msg: x)
            buffer_view_list.set(x.id, e, self)
        case .buffer_view_delete(let x):
            buffer_view_list.erase(x.id)
            
        case .material_create(let x):
            let e = NooMaterial(msg: x)
            material_list.set(x.id, e, self)
        case .material_update(_):
            break
        case .material_delete(let x):
            material_list.erase(x.id)
            
        case .image_create(_):
            break
        case .image_delete(_):
            break
            
        case .texture_create(_):
            break
        case .texture_delete(_):
            break
            
        case .sampler_create(_):
            break
        case .sampler_delete(_):
            break
            
        case .light_create(_):
            break
        case .light_update(_):
            break
        case .light_delete(_):
            break
            
        case .geometry_create(let x):
            let e = NooGeometry(msg: x)
            geometry_list.set(x.id, e, self)
        case .geometry_delete(let x):
            geometry_list.erase(x.id)
            
        case .table_create(_):
            break
        case .table_update(_):
            break
        case .table_delete(_):
            break
            
        case .document_update(_):
            break
        case .document_reset(_):
            break
            
        case .signal_invoke(_):
            break
            
        case .method_reply(_):
            break
            
        case .document_initialized(_):
            break
        }
    }
}

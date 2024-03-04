//
//  NoodlesWorld.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/16/24.
//

import Foundation
import SwiftUI
import OSLog
import RealityKit
import RealityKitContent

final class NInstallGesture : Event {
    let entity : NEntity
    
    init(entity: NEntity) {
        self.entity = entity
    }
}

protocol NoodlesComponent {
    func create(world: NoodlesWorld);
    func destroy(world: NoodlesWorld);
}

class NooBuffer : NoodlesComponent {
    var info: MsgBufferCreate
    
    init(msg: MsgBufferCreate) {
        info = msg
    }
    
    func create(world: NoodlesWorld) {
        print("Created buffer")
    }
    
    func destroy(world: NoodlesWorld) { }
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
    
    func destroy(world: NoodlesWorld) { }
}

class NooTexture : NoodlesComponent {
    var info : MsgTextureCreate
    
    var noo_world : NoodlesWorld!
    
    private var resources : [TextureResource.Semantic : TextureResource] = [:]
    
    init(msg: MsgTextureCreate) {
        info = msg
    }
    
    func create(world: NoodlesWorld) {
        noo_world = world
    }
    
    func get_texture_resource_for(semantic: TextureResource.Semantic) -> TextureResource? {
        
        if let resource = resources[semantic] {
            return resource
        }
        
        guard let img = noo_world.image_list.get(info.image_id) else {
            default_log.error("Image is missing!")
            return nil
        }
        
        // TODO: Update spec to help inform APIs about texture use
        do {
            let resource = try TextureResource.generate(from: img.image, options: .init(semantic: semantic, mipmapsMode: .allocateAndGenerateAll))
            
            resources[semantic] = resource
            
            return resource
        } catch let error {
            default_log.error("Unable to create texture: \(error.localizedDescription)")
        }
        
        return nil
    }
    
    func destroy(world: NoodlesWorld) { }
}

class NooSampler : NoodlesComponent {
    var info : MsgSamplerCreate
    
    init(msg: MsgSamplerCreate) {
        info = msg
    }
    
    func create(world: NoodlesWorld) {
        
    }
    
    func destroy(world: NoodlesWorld) { }
}

class NooImage : NoodlesComponent {
    var info : MsgImageCreate
    
    var image : CGImage!
    
    init(msg: MsgImageCreate) {
        info = msg
    }
    
    func create(world: NoodlesWorld) {
        let src_bytes = get_slice(world: world)
        
        //let is_jpg = src_bytes.starts(with: [0xFF, 0xD8, 0xFF])
        //let is_png = src_bytes.starts(with: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
        
        image = UIImage(data: src_bytes)?.cgImage
        
        print("Creating image: \(image.width)x\(image.height)");
    }
    
    func get_slice(world: NoodlesWorld) -> Data {
        if let d = info.saved_bytes {
            return d
        }
        
        if let v_id = info.buffer_source {
            if let v = world.buffer_view_list.get(v_id) {
                return v.get_slice(offset: 0)
            }
        }
        
        return Data()
    }
    
    func destroy(world: NoodlesWorld) { }
}

private func resolve_texture(world: NoodlesWorld, semantic: TextureResource.Semantic, ref: TexRef) -> MaterialParameters.Texture? {
    guard let tex_info = world.texture_list.get(ref.texture) else {
        return nil
    }
    
    // can add sampler in here
    guard let resource = tex_info.get_texture_resource_for(semantic: semantic) else {
        return nil
    }
    
    return MaterialParameters.Texture(resource);
}

class NooMaterial : NoodlesComponent {
    var info: MsgMaterialCreate
    
    var mat : (any RealityKit.Material)!
    
    init(msg: MsgMaterialCreate) {
        info = msg
    }
    
    func create(world: NoodlesWorld) {
        print("Creating NooMaterial")
        
        var tri_mat = PhysicallyBasedMaterial()
        
        tri_mat.baseColor = PhysicallyBasedMaterial.BaseColor.init(tint: info.pbr_info.base_color)
        
        if let x = info.pbr_info.base_color_texture {
            if let tex_info = resolve_texture(world: world, semantic: .color, ref: x) {
                tri_mat.baseColor.texture = tex_info;
                
            } else {
                print("Missing texture!")
            }
        }
        
        if let x = info.normal_texture {
            if let tex_info = resolve_texture(world: world, semantic: .normal, ref: x) {
                tri_mat.normal = PhysicallyBasedMaterial.Normal(texture: tex_info);
                
            } else {
                print("Missing texture!")
            }
        }
        
        tri_mat.roughness = PhysicallyBasedMaterial.Roughness(floatLiteral: info.pbr_info.roughness)
        tri_mat.metallic = PhysicallyBasedMaterial.Metallic(floatLiteral: info.pbr_info.metallic)
        
        mat = tri_mat
        
        print("Created material")
    }
    
    func destroy(world: NoodlesWorld) { }
}

class NooGeometry : NoodlesComponent {
    var info: MsgGeometryCreate
    
    var mesh_resources: [MeshResource] = []
    var mesh_materials: [any RealityKit.Material] = []
    
    var bounding_box: BoundingBox = BoundingBox()
    
    init(msg: MsgGeometryCreate) {
        info = msg
    }
    
    func create(world: NoodlesWorld) {
        for patch in info.patches {
            add_patch(patch, world)
        }
        
        for res in mesh_resources {
            bounding_box = res.bounds.union(bounding_box)
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
                
            case "TEXTURE":
                switch attrib.format {
                case "VEC2":
                    let attrib_data = realize_tex_vec2(slice, vcount: Int(patch.vertex_count), stride: Int(attrib.stride))
                    description.textureCoordinates = MeshBuffers.TextureCoordinates(attrib_data);
                case "U16VEC2":
                    let attrib_data = realize_tex_u16vec2(slice, vcount: Int(patch.vertex_count), stride: Int(attrib.stride))
                    description.textureCoordinates = MeshBuffers.TextureCoordinates(attrib_data);
                default:
                    print("Unknown texture coord format \(attrib.format)")
                }
                
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
    
    func destroy(world: NoodlesWorld) { }
}

class NEntity : Entity, HasCollision {
    
}

class NooEntity : NoodlesComponent {
    var last_info: MsgEntityCreate
    
    var entity: NEntity
    
    var sub_entities: [Entity]
    
    init(msg: MsgEntityCreate) {
        last_info = msg
        entity = NEntity()
        sub_entities = []
        
        //assert(((entity as? HasCollision) != nil))
        //assert(((entity as? HasHierarchy) != nil))
    }
    
    func common(world: NoodlesWorld, msg: MsgEntityCreate) {
        // setting parent?
        if let parent = msg.parent {
            // a set or unset?
            if parent.is_valid() {
                let parent_ent = world.entity_list.get(parent)!
                parent_ent.entity.addChild(entity)
            } else {
                world.root_entity.addChild(entity)
            }
        }
        
        if let tf = msg.tf {
            entity.move(to: tf, relativeTo: entity.parent, duration: 1)
        }
        
        if let _ = msg.null_rep {
            unset_representation(world);
        } else if let g = msg.rep {
            set_render_representation(g, world)
        }
    }
    
    func create(world: NoodlesWorld) {
        world.scene.add(entity)
        world.root_entity.addChild(entity)
        
        common(world: world, msg: last_info)
        
        print("Created entity")
    }
    
    func unset_representation(_ world: NoodlesWorld) {
        clear_subs(world)
    }
    
    func set_render_representation(_ rep: RenderRep, _ world: NoodlesWorld) {
        unset_representation(world)
        
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
        
        let bb = geom.bounding_box
        
        let cc = CollisionComponent(shapes: [ShapeResource.generateBox(size: bb.extents).offsetBy(translation: bb.center)]);
        
        entity.collision = cc
    }
    
    func update_methods(_ world: NoodlesWorld, _ method_list: [NooID] ) {
        
    }
    
    func update(world: NoodlesWorld, _ update: MsgEntityCreate) {
        common(world: world, msg: update)
        last_info = update
    }
    
    private func clear_subs(_ world: NoodlesWorld) {
        for sub_entity in sub_entities {
            world.scene.remove(sub_entity)
        }
        sub_entities.removeAll(keepingCapacity: true)
    }
    
    func destroy(world: NoodlesWorld) {
        clear_subs(world)
        world.scene.remove(entity)
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

func realize_tex_u16vec2(_ data: Data, vcount: Int, stride: Int) -> [SIMD2<Float>] {
    let true_stride = max(stride, 2*2);
    
    return data.withUnsafeBytes {
        (pointer: UnsafeRawBufferPointer) -> [SIMD2<Float>] in
        
        var ret : [SIMD2<Float>] = []
        
        ret.reserveCapacity(vcount)
        
        for vertex_i in 0 ..< vcount {
            let place = vertex_i * true_stride
            let item = pointer.loadUnaligned(fromByteOffset: place, as: SIMD2<UInt16>.self)
            var p = SIMD2<Float>(item) / Float(UInt16.max)
            p.y = 1.0 - p.y;
            ret.append( p )
        }
        
        return ret
    }
}


func realize_tex_vec2(_ data: Data, vcount: Int, stride: Int) -> [SIMD2<Float>] {
    let true_stride = max(stride, 2*4);
    
    return data.withUnsafeBytes {
        (pointer: UnsafeRawBufferPointer) -> [SIMD2<Float>] in
        
        var ret : [SIMD2<Float>] = []
        
        ret.reserveCapacity(vcount)
        
        for vertex_i in 0 ..< vcount {
            let place = vertex_i * true_stride
            var p = pointer.loadUnaligned(fromByteOffset: place, as: SIMD2<Float>.self)
            p.y = 1.0 - p.y;
            ret.append( p )
        }
        
        return ret
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
    
    func erase(_ id: NooID, _ world: NoodlesWorld) {
        if let v = list.removeValue(forKey: id.slot) {
            v.destroy(world: world)
        }
    }
}

class NoodlesWorld {
    var scene : RealityViewContent;
    
    //var install_gesture_publisher :
    
    //public var methods_list = ComponentList<MsgMethodCreate>()
    //public var signals_list = ComponentList<MsgSignalCreate>()
    
    public var entity_list = ComponentList<NooEntity>()
    //public var plot_list = ComponentList<MsgPlotCreate>()
    //public var table_list = ComponentList<MsgTableCreate>()
    
    public var material_list = ComponentList<NooMaterial>()
    
    public var geometry_list = ComponentList<NooGeometry>()
    
    //public var light_list = ComponentList<MsgLightCreate>()
    
    public var image_list = ComponentList<NooImage>()
    public var texture_list = ComponentList<NooTexture>()
    public var sampler_list = ComponentList<NooSampler>()
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
        case .entity_update(let x):
            if let item = entity_list.get(x.id) {
                item.update(world: self, x);
            }
        case .entity_delete(let x):
            entity_list.erase(x.id, self)
            
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
            buffer_list.erase(x.id, self)
            
        case .buffer_view_create(let x):
            let e = NooBufferView(msg: x)
            buffer_view_list.set(x.id, e, self)
        case .buffer_view_delete(let x):
            buffer_view_list.erase(x.id, self)
            
        case .material_create(let x):
            let e = NooMaterial(msg: x)
            material_list.set(x.id, e, self)
        case .material_update(_):
            break
        case .material_delete(let x):
            material_list.erase(x.id, self)
            
        case .image_create(let x):
            let e = NooImage(msg: x)
            image_list.set(x.id, e, self)
        case .image_delete(let x):
            image_list.erase(x.id, self)
            
        case .texture_create(let x):
            let e = NooTexture(msg: x)
            texture_list.set(x.id, e, self)
        case .texture_delete(let x):
            texture_list.erase(x.id, self)
            
        case .sampler_create(let x):
            let e = NooSampler(msg: x)
            sampler_list.set(x.id, e, self)
        case .sampler_delete(let x):
            sampler_list.erase(x.id, self)
            
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
            geometry_list.erase(x.id, self)
            
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
    
    func frame_all(target_volume : SIMD3<Float> = SIMD3<Float>(2,1,2)) {
        let bounds = root_entity.visualBounds(recursive: true, relativeTo: root_entity.parent)
        
        // ok has to be a better way to do this
        
        let target_box = target_volume
        
        let scales = target_box / (bounds.extents * 1.5)
        
        let new_uniform_scale = scales.min()
        
        var current_tf = root_entity.transform
        
        current_tf.translation = -bounds.center * new_uniform_scale
        current_tf.scale = SIMD3<Float>(repeating: new_uniform_scale)
        
        root_entity.move(to: current_tf, relativeTo: root_entity.parent, duration: 2)
    }
}

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
import SwiftCBOR
import Combine

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

class NooMethod : NoodlesComponent, Hashable {
    var info: MsgMethodCreate
    
    init(msg: MsgMethodCreate) {
        info = msg
    }
    
    func create(world: NoodlesWorld) {
        world.method_list_lookup[info.name] = self
    }
    
    func destroy(world: NoodlesWorld) { 
        world.method_list_lookup.removeValue(forKey: info.name)
    }
    
    static func == (lhs: NooMethod, rhs: NooMethod) -> Bool {
        return lhs.info == rhs.info
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(info)
    }
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
        return info.get_slice(data: buffer.info.bytes, view_offset: offset)
    }
    
    func get_slice(offset: Int64, length: Int64) -> Data {
        return info.get_slice(data: buffer.info.bytes, view_offset: offset, override_length: length)
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
    
    var descriptors   : [MeshDescriptor] = []
    var mesh_materials: [any RealityKit.Material] = []
    
    var pending_mesh_resources: [MeshResource] = []
    
    var pending_bounding_box: BoundingBox?
    
    init(msg: MsgGeometryCreate) {
        info = msg
    }
    
    func get_mesh_resources() async -> [MeshResource] {
        //print("asking for mesh resources")
        if !pending_mesh_resources.isEmpty {
            //print("early return")
            return pending_mesh_resources
        }
        
        for d in descriptors {
            let res = try! await MeshResource.init(from: [d])
            self.pending_mesh_resources.append( res )
        }
        
        //print("built")
        
        return pending_mesh_resources
    }
    
    func get_bounding_box() async -> BoundingBox {
        //print("get bounding box")
        
        if let bb = self.pending_bounding_box {
            //print("early return")
            return bb
        }
        var bounding_box = BoundingBox()
        let resources = await get_mesh_resources()
        for res in resources {
            bounding_box = await res.bounds.union(bounding_box)
        }
        
        pending_bounding_box = bounding_box
        
        //print("built")
        
        return bounding_box
    }
    
    func create(world: NoodlesWorld) {
        for patch in info.patches {
            add_patch(patch, world)
        }
        
        print("Created geometry")
    }
    
    func add_patch(_ patch: GeomPatch, _ world: NoodlesWorld) {
        guard let description = patch.resource else {
            return
        }
          
        if let mat = world.material_list.get(patch.material) {
            mesh_materials.append( mat.mat )
        } else {
            var tri_mat = PhysicallyBasedMaterial()
            tri_mat.baseColor = PhysicallyBasedMaterial.BaseColor.init(tint: .white)
            mesh_materials.append( tri_mat )
        }
        
        descriptors.append(description)
    }
    
    func destroy(world: NoodlesWorld) { }
    
    func generate_emulated_instances(world: NoodlesWorld, src: InstanceSource) async -> [MeshDescriptor]  {
        assert(src.stride < (4*4*4));
        
        guard let v = world.buffer_view_list.get(src.view) else {
            print("Warning: missing instance view")
            return []
        }
        
        let slice = v.get_slice(offset: 0)
        
        let instance_list = realize_mat4(slice)
        
        print("Building \(instance_list.count) instances")
        
        /*
         | p~x~ | c~r~ | r~x~ | s~x~
         | p~y~ | c~g~ | r~y~ | s~y~
         | p~z~ | c~b~ | r~z~ | s~z~
         | tx   | c~a~ | r~w~ | ty
         */
        
        var emulated_descriptors : [MeshDescriptor] = []
        
        let instance_count = instance_list.count
        
        // nonoptimal looping, but this is all non-optimal anyway
        for patch in descriptors {
            
            let v_count = patch.positions.count
            var f_count = 0;
            
            if let prims = patch.primitives {
                if case let MeshDescriptor.Primitives.triangles(x) = prims {
                    f_count = x.count
                }
            }
            
            print("Realizing patch with \(v_count) verts and \(f_count) indicies")
            
            assert(f_count * instance_list.count < UInt32.max);
            
            var position_cache : [SIMD3<Float>] = []
            position_cache.reserveCapacity(v_count * instance_count)
            var normal_cache : [SIMD3<Float>] = []
            if let _ = patch.normals {
                normal_cache.reserveCapacity(v_count * instance_count)
            }
            var tangent_cache : [SIMD3<Float>] = []
            if let _ = patch.tangents {
                tangent_cache.reserveCapacity(v_count * instance_count)
            }
            var bitangent_cache : [SIMD3<Float>] = []
            if let _ = patch.bitangents {
                bitangent_cache.reserveCapacity(v_count * instance_count)
            }
            var tex_cache : [SIMD2<Float>] = []
            if let _ = patch.textureCoordinates {
                tex_cache.reserveCapacity(v_count * instance_count)
            }
            
            var index_cache : [UInt32] = []
            index_cache.reserveCapacity(f_count * instance_count)
            
            for imat in instance_list {
                let (ipos,_,irot,iscale) = imat.columns
                
                let irot_quat = simd_quaternion(irot.x, irot.y, irot.z, irot.w)
                let scale     = vec4_to_vec3(iscale)
                let texture   = simd_float2(ipos.w, iscale.w)
                
                if let prims = patch.primitives {
                    if case let MeshDescriptor.Primitives.triangles(x) = prims {
                        let offset = UInt32(position_cache.count);
                        for pi in x {
                            index_cache.append(pi + offset)
                        }
                        
                    }
                }
                
                for mesh_pos in patch.positions {
                    let pos = irot_quat.act(mesh_pos * scale) + vec4_to_vec3(ipos)
                    position_cache.append(pos)
                }
                
                if let mesh_normals = patch.normals {
                    for mesh_normal in mesh_normals {
                        normal_cache.append(irot_quat.act(mesh_normal))
                    }
                }
                
                if let mesh_tangents = patch.tangents {
                    for vector in mesh_tangents {
                        tangent_cache.append(irot_quat.act(vector))
                    }
                }
                
                if let mesh_bitangents = patch.bitangents {
                    for vector in mesh_bitangents {
                        bitangent_cache.append(irot_quat.act(vector))
                    }
                }
                
                if let mesh_texs = patch.textureCoordinates {
                    for mesh_tex in mesh_texs {
                        tex_cache.append(mesh_tex + texture)
                    }
                }
                
            }
            
            for o in index_cache {
                assert(o < position_cache.count)
            }
            
            var new_desc = MeshDescriptor()
            
            new_desc.positions = MeshBuffers.Positions(position_cache)
            
            if !normal_cache.isEmpty {
                new_desc.normals = MeshBuffers.Normals(normal_cache)
            }
            
            if !tangent_cache.isEmpty {
                new_desc.tangents = MeshBuffers.Tangents(tangent_cache)
            }
            
            if !bitangent_cache.isEmpty {
                new_desc.bitangents = MeshBuffers.Tangents(bitangent_cache)
            }
            
            if !tex_cache.isEmpty {
                new_desc.textureCoordinates = MeshBuffers.TextureCoordinates(tex_cache)
            }
            
            new_desc.primitives = .triangles(index_cache)
            
            emulated_descriptors.append(new_desc)
        }
        
        return emulated_descriptors
    }
}

class NEntity : Entity, HasCollision {
    
}

struct SpecialAbilities {
    var can_move = false
    var can_scale = false
    var can_rotate = false
    
    var can_probe = false
    
    var can_select = false
    
    var can_activate = false
    
    init() {
        
    }
    
    init(_ list: [NooMethod]) {
        let set = Set(list.map{ $0.info.name })
        
        can_activate = set.contains(CommonStrings.activate)
        
        can_move = set.contains(CommonStrings.set_position)
        can_scale = set.contains(CommonStrings.set_scale)
        can_rotate = set.contains(CommonStrings.set_rotation)
        
        can_select = set.contains(CommonStrings.select_region)
        
        can_probe = set.contains(CommonStrings.probe_at)
    }
}

class NooEntity : NoodlesComponent {
    var last_info: MsgEntityCreate
    
    var entity: NEntity
    
    var sub_entities: [Entity] = []
    
    var methods: [NooMethod] = []
    var abilities = SpecialAbilities()
    
    init(msg: MsgEntityCreate) {
        last_info = msg
        entity = NEntity()
    }
    
    func common(world: NoodlesWorld, msg: MsgEntityCreate) {
        dump(msg)
        
        if let n = msg.name {
            entity.name = n
        }
        
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
            handle_new_tf(world, transform: tf)
        }
        
        if let _ = msg.null_rep {
            unset_representation(world);
        } else if let g = msg.rep {
            print("adding mesh rep")
            unset_representation(world);
            
            Task {
                let new_subs = await self.build_sub_render_representation(g, world);
                
                DispatchQueue.main.async {
                    for sub in new_subs {
                        self.add_sub(world, sub)
                    }
                    
                    print("adding mesh rep done")
                }

            }
        }
        
        if let mthds = msg.methods_list {
            methods = mthds.compactMap {
                world.methods_list.get($0)
            }
            
            //print("Adding entity methods")
            //dump(methods)
            
            abilities = SpecialAbilities(methods)
            
            if abilities.can_move || abilities.can_rotate || abilities.can_scale {
                install_gesture_control(world)
            }
        }
    }
    
    func handle_new_tf(_ world: NoodlesWorld, transform: simd_float4x4) {
        // DONT update the transform if the user is currently working on it!
        // this is a bad fix, because the update might HAVE to go through
        // TODO: Use the last updated transform on editing end!
        if entity.gestureComponent != nil {
            let shared = EntityGestureState.shared
            if shared.targetedEntity == entity {
                if shared.isDragging || shared.isRotating || shared.isScaling {
                    
                    return;
                }
            }
        }
        
        entity.move(to: transform, relativeTo: entity.parent, duration: 1)
    }
    
    func install_gesture_control(_ world: NoodlesWorld) {
        print("Installing gesture controls...")
        
        // this gets called AFTER we do a render rep
        // if there is NO render rep, nothing will work
        
        let gesture = GestureComponent(canDrag: abilities.can_move,
                                       pivotOnDrag: false,
                                       canScale: abilities.can_scale,
                                       canRotate: abilities.can_rotate
        )
        var input = InputTargetComponent()
        input.isEnabled = false
        let support = GestureSupportComponent(
            world: world, noo_id: last_info.id
        )
        entity.components.set(gesture)
        entity.components.set(input)
        entity.components.set(support)
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
    
    func add_sub(_ world: NoodlesWorld, _ ent: Entity) {
        world.scene.add(ent)
        
        sub_entities.append(ent)
        
        entity.addChild(ent)
    }
    
    func build_sub_render_representation(_ rep: RenderRep, _ world: NoodlesWorld) async -> [Entity] {  
        var subs = [Entity]();
        
        guard let geom = world.geometry_list.get(rep.mesh) else {
            print("Unable to find geometry")
            return []
        }
        
        var bb = BoundingBox()
        
        if let instances = rep.instances {
            
            let mat = geom.mesh_materials[0]
            
            let generated = await geom.generate_emulated_instances(world: world, src: instances)
            
            do  {
                let resource = try await MeshResource.generate(from: generated)
                
                let new_entity = await ModelEntity(mesh: resource, materials: [mat])
                
                subs.append(new_entity)
            } catch {
                print("Uh oh \(error)");
                assert(false)
            }
            
        } else {
            for (mat, mesh) in zip(geom.mesh_materials, await geom.get_mesh_resources()) {
                let new_entity = await ModelEntity(mesh: mesh, materials: [mat])
                
                subs.append(new_entity)
            }
            
            bb = await geom.get_bounding_box()
        }

        let cc = await CollisionComponent(shapes: [ShapeResource.generateBox(size: bb.extents).offsetBy(translation: bb.center)]);
        
        await entity.components.set(cc);
        
        return subs
    }
    
    func update(world: NoodlesWorld, _ update: MsgEntityCreate) {
        common(world: world, msg: update)
        last_info = update
    }
    
    private func clear_subs(_ world: NoodlesWorld) {
        print("Clearing subs!")
        for sub_entity in sub_entities {
            world.scene.remove(sub_entity)
            entity.removeChild(sub_entity)
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

func realize_mat4(_ data: Data) -> [simd_float4x4] {
    let mat_count = data.count / (4*4*4);
    
    return data.withUnsafeBytes {
        (pointer: UnsafeRawBufferPointer) -> [simd_float4x4] in
        
        var ret : [simd_float4x4] = []
        
        ret.reserveCapacity(mat_count)
        
        for mat_i in 0 ..< mat_count {
            let place = mat_i * (4*4*4)
            ret.append( pointer.loadUnaligned(fromByteOffset: place, as: simd_float4x4.self) )
        }
        
        return ret
    }
}

func vec4_to_vec3(_ v : simd_float4) -> simd_float3 {
    return simd_float3(v.x, v.y, v.z)
}

func matrix_multiply(_ mat: simd_float4x4, _ v : simd_float3) -> simd_float3 {
    let v4 = simd_float4(v, 1.0)
    let ret = matrix_multiply(mat, v4)
    return vec4_to_vec3(ret) / ret.w
}

//func realize_index(_ buffer_view: NooBufferView, _ idx: GeomIndex) -> [UInt32] {
//    if idx.stride != 0 {
//        fatalError("Unable to handle strided index buffers")
//    }
//    
//    let byte_count : Int64;
//    switch idx.format {
//    case "U8":
//        byte_count = idx.count
//    case "U16":
//        byte_count = idx.count*2
//    case "U32":
//        byte_count = idx.count*4
//    default:
//        fatalError("unknown index format")
//    }
//    
//    // TODO: there is something weird here
//    
//    let slice = buffer_view.get_slice(offset: idx.offset, length: byte_count)
//    
//    return slice.withUnsafeBytes { (pointer: UnsafeRawBufferPointer) -> [UInt32] in
//        
//        switch idx.format {
//        case "U8":
//            let arr = pointer.bindMemory(to: UInt8.self)
//            return Array<UInt8>(arr).map { UInt32($0) }
//            
//        case "U16":
//            let arr = pointer.bindMemory(to: UInt16.self)
//            return Array<UInt16>(arr).map { UInt32($0) }
//
//        case "U32":
//            let arr = pointer.bindMemory(to: UInt32.self)
//            return Array<UInt32>(arr)
//            
//        default:
//            fatalError("unknown index format")
//        }
//    }
//}

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
    var scene : RealityViewContent
    
    weak var comm: NoodlesCommunicator?
    
    //var install_gesture_publisher :
    
    public var methods_list = ComponentList<NooMethod>()
    public var method_list_lookup = [String: NooMethod]()
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
    
    public var attached_method_list = [NooMethod]()
    public var visible_method_list: MethodListObservable
    
    public var invoke_mapper = [String:(MsgMethodReply) -> ()]()
    
    var root_entity : Entity
    
    init(_ scene: RealityViewContent, _ doc_method_list: MethodListObservable, initial_offset: simd_float3 = .zero) {
        self.scene = scene
        self.visible_method_list = doc_method_list
        
        root_entity = MeshGeneration.build_sphere()
        
        let bb = root_entity.visualBounds(relativeTo: root_entity.parent)
        let gesture = GestureComponent(canDrag: true, canScale: true, canRotate: false)
        let input = InputTargetComponent()
        let coll  = CollisionComponent(shapes: [ShapeResource.generateSphere(radius: bb.boundingRadius)])
        root_entity.components.set(gesture)
        root_entity.components.set(input)
        root_entity.components.set(coll)
        root_entity.name = "Root Entity"
        
        scene.add(root_entity)
        
        root_entity.transform.translation = initial_offset
        
        print("Creating root entity:")
        dump(root_entity)
    }
    
    func handle_message(_ msg: FromServerMessage) {
        switch (msg) {
            
        case .method_create(let x):
            let e = NooMethod(msg: x)
            methods_list.set(x.id, e, self)
        case .method_delete(let x):
            methods_list.erase(x.id, self)
            
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
            
        case .document_update(let x):
            print("updating document methods and signals")
            self.attached_method_list = x.methods_list?.compactMap({f in methods_list.get(f)}) ?? []
            
            self.visible_method_list.list.removeAll();
            
            for m in self.attached_method_list {
                self.visible_method_list.list.append(AvailableMethod(method: m, context_type: String()))
            }

        case .document_reset(_):
            break
            
        case .signal_invoke(_):
            break
            
        case .method_reply(let x):
            print("Got method reply")
            if let value = self.invoke_mapper[x.invoke_id] {
                print("Has value, execute")
                value(x)
            }
            self.invoke_mapper.removeValue(forKey: x.invoke_id)
            
        case .document_initialized(_):
            break
        }
    }
    
    func frame_all(target_volume : SIMD3<Float>) {
        
        // check if we need to just reset scale
        
        if root_entity.transform.scale.x != 1.0 {
            var current_tf = root_entity.transform
            
            current_tf.translation = .zero
            current_tf.scale = .one
            current_tf.rotation = simd_quatf(ix: 0, iy: 0, iz: 0, r: 1)
            
            root_entity.move(to: current_tf, relativeTo: root_entity.parent, duration: 2)
            return
        }
        
        let bounds = root_entity.visualBounds(recursive: true, relativeTo: root_entity.parent)
        
        print("Frame bounds \(bounds) \(bounds.center)");
        
        // ok has to be a better way to do this
        
        let target_box = target_volume
        
        let scales = target_box / (bounds.extents)
        
        print("Scales \(scales)")
        
        let new_uniform_scale = scales.min()
        
        print("Scales min \(new_uniform_scale)")
        
        var current_tf = root_entity.transform
        
        current_tf.translation = -bounds.center * new_uniform_scale
        //current_tf.translation = -bounds.center
        current_tf.scale = SIMD3<Float>(repeating: new_uniform_scale)
        
        root_entity.move(to: current_tf, relativeTo: root_entity.parent, duration: 2)
    }
    
    func invoke_method(method: NooID, 
                       context: InvokeMessageOn,
                       args: [CBOR],
                       on_done: ((MsgMethodReply) -> Void)? = nil
    ) {
        print("Launch")
        
        // generate id
        
        var message = InvokeMethodMessage(method: method, context: context, args: args)
        
        //dump(message)
        
        if let od = on_done {
            let id = UUID().uuidString
            
            print("New id is \(id)")
            
            message.invoke_id = id
            self.invoke_mapper[id] = od
        }
        
        comm!.send(msg: message)
    }
    
    func invoke_method_by_name(method_name: String,
                               context: InvokeMessageOn,
                               args: [CBOR],
                               on_done: ((MsgMethodReply) -> Void)? = nil
    ) {
        guard let mthd = method_list_lookup[method_name] else { return }
        
        invoke_method(method: mthd.info.id, context: context, args: args, on_done: on_done)
    }
    
    func set_all_entity_input(enabled: Bool) {
        print("Setting input component", enabled)
        for (_,v) in entity_list.list {
            if var c = v.entity.components[InputTargetComponent.self] {
                c.isEnabled = enabled
            }
        }
    }
}

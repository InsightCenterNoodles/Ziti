//
//  Messages.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 2/13/24.
//

import Foundation
import SwiftCBOR
import OSLog
import simd
import UIKit

protocol NoodlesMessage {
    static var message_id: Int { get }
    
    func to_cbor() -> CBOR
}

protocol NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self
}

var default_log = Logger()

struct MessageDecoder {
    private static func decode_single(mid: CBOR, content: CBOR) -> FromServerMessage? {
        
        switch to_int64(mid)  {
            case 0 :  
            return FromServerMessage.method_create(MsgMethodCreate.from_cbor(c: content))
        case  1 :  return FromServerMessage.method_delete(MsgCommonDelete.from_cbor(c: content))
        case  2 :  return FromServerMessage.signal_create(MsgSignalCreate.from_cbor(c: content))
        case  3 :  return FromServerMessage.signal_delete(MsgCommonDelete.from_cbor(c: content))
        case  4 :  return FromServerMessage.entity_create(MsgEntityCreate.from_cbor(c: content))
        case  5 :  return FromServerMessage.entity_update(MsgEntityUpdate.from_cbor(c: content))
        case  6 :  return FromServerMessage.entity_delete(MsgCommonDelete.from_cbor(c: content))
        case  7 :  return FromServerMessage.plot_create(MsgPlotCreate.from_cbor(c: content))
        case  8 :  return FromServerMessage.plot_update(MsgPlotUpdate.from_cbor(c: content))
        case  9 :  return FromServerMessage.plot_delete(MsgCommonDelete.from_cbor(c: content))
        case  10 :  return FromServerMessage.buffer_create(MsgBufferCreate.from_cbor(c: content))
        case  11 :  return FromServerMessage.buffer_delete(MsgCommonDelete.from_cbor(c: content))
        case  12 :  return FromServerMessage.buffer_view_create(MsgBufferViewCreate.from_cbor(c: content))
        case  13 :  return FromServerMessage.buffer_view_delete(MsgCommonDelete.from_cbor(c: content))
        case  14 :  return FromServerMessage.material_create(MsgMaterialCreate.from_cbor(c: content))
        case  15 :  return FromServerMessage.material_update(MsgMaterialUpdate.from_cbor(c: content))
        case  16 :  return FromServerMessage.material_delete(MsgCommonDelete.from_cbor(c: content))
        case  17 :  return FromServerMessage.image_create(MsgImageCreate.from_cbor(c: content))
        case  18 :  return FromServerMessage.image_delete(MsgCommonDelete.from_cbor(c: content))
        case  19 :  return FromServerMessage.texture_create(MsgTextureCreate.from_cbor(c: content))
        case  20 :  return FromServerMessage.texture_delete(MsgCommonDelete.from_cbor(c: content))
        case  21 :  return FromServerMessage.sampler_create(MsgSamplerCreate.from_cbor(c: content))
        case  22 :  return FromServerMessage.sampler_delete(MsgCommonDelete.from_cbor(c: content))
        case  23 :  return FromServerMessage.light_create(MsgLightCreate.from_cbor(c: content))
        case  24 :  return FromServerMessage.light_update(MsgLightUpdate.from_cbor(c: content))
        case  25 :  return FromServerMessage.light_delete(MsgCommonDelete.from_cbor(c: content))
        case  26 :  return FromServerMessage.geometry_create(MsgGeometryCreate.from_cbor(c: content))
        case  27 :  return FromServerMessage.geometry_delete(MsgCommonDelete.from_cbor(c: content))
        case  28 :  return FromServerMessage.table_create(MsgTableCreate.from_cbor(c: content))
        case  29 :  return FromServerMessage.table_update(MsgTableUpdate.from_cbor(c: content))
        case  30 :  return FromServerMessage.table_delete(MsgCommonDelete.from_cbor(c: content))
        case  31 :  return FromServerMessage.document_update(MsgDocumentUpdate.from_cbor(c: content))
        case  32 :  return FromServerMessage.document_reset(MsgDocumentReset.from_cbor(c: content))
        case  33 :  return FromServerMessage.signal_invoke(MsgSignalInvoke.from_cbor(c: content))
        case  34 :  return FromServerMessage.method_reply(MsgMethodReply.from_cbor(c: content))
        case  35 :  return FromServerMessage.document_initialized(MsgDocumentInitialized.from_cbor(c: content))
        default:
            return nil
        }

    }
    
    func decode(bytes: ArraySlice<UInt8>) -> [FromServerMessage] {
        var ret : [FromServerMessage] = []
        
        guard let decoded = try? CBORDecoder(input: bytes, options: CBOROptions()).decodeItem() else {
            default_log.critical("Malformed message from server: Invalid CBOR")
            return []
        }
        
        guard case let CBOR.array(array) = decoded else {
            default_log.critical("Malformed message from server: Message is not CBOR array")
            return []
        }
        
        if array.count % 2 != 0 {
            default_log.critical("Malformed message from server: Message count is not mod 2")
            return []
        }
        
        for i in stride(from: 0, to: array.count, by: 2) {
            let mid = array[i]
            let content = array[i+1]
            
            guard let msg = MessageDecoder.decode_single(mid: mid, content: content) else {
                //default_log.warning("Unable to decode message \(mid)")
                continue
            }
            
            ret.append(msg)
        }
        
        return ret
    }
}

//

public extension CBOR {
    static func int64(_ int: Int64) -> CBOR {
        if int < 0 {
            return CBOR.negativeInt(UInt64(abs(int)-1))
        } else {
            return CBOR.unsignedInt(UInt64(int))
        }
    }
}

func to_int64(_ c: CBOR) -> Int64? {
    if case let CBOR.negativeInt(x) = c {
        return Int64(x) + 1
    }
    if case let CBOR.unsignedInt(x) = c {
        return Int64(x)
    }
    return nil
}

func to_int64(_ mc: CBOR?) -> Int64? {
    guard let c = mc else {
        return nil
    }
    if case let CBOR.negativeInt(x) = c {
        return Int64(x) + 1
    }
    if case let CBOR.unsignedInt(x) = c {
        return Int64(x)
    }
    return nil
}

func to_string(_ c: CBOR) -> String {
    if case let CBOR.utf8String(string) = c {
        return string
    }
    return String()
}

func to_string(_ mc: CBOR?) -> String? {
    guard let c = mc else {
        return nil
    }
    if case let CBOR.utf8String(string) = c {
        return string
    }
    return String()
}

func to_id(_ mc: CBOR?) -> NooID? {
    guard let c = mc else {
        return nil
    }
    return NooID(c)
}

func to_float(_ mc: CBOR?) -> Float? {
    guard let c = mc else {
        return nil
    }
    
    switch c {
    case .unsignedInt(let x):
        return Float(x)
    case .negativeInt(let x):
        return Float(x + 1)
    case .half(let x):
        return Float(x)
    case .float(let x):
        return Float(x)
    case .double(let x):
        return Float(x)
    default:
        return nil
    }
}

func to_float_array(_ mc: CBOR?) -> [Float]? {
    if case let Optional<CBOR>.some(CBOR.array(arr)) = mc {
        var ret : Array<Float> = []
        for att in arr {
            ret.append(to_float(att) ?? 0.0)
        }
        return ret
    }
    return nil
}

func to_mat4(_ mc: CBOR?) -> simd_float4x4? {
    guard let arr = to_float_array(mc) else {
        return nil
    }
    
    if arr.count < 16 {
        return nil
    }
    
    
    return simd_float4x4(SIMD4<Float>(arr[0...3]),
                  SIMD4<Float>(arr[4...7]),
                  SIMD4<Float>(arr[8...11]),
                  SIMD4<Float>(arr[12...15]));
}

func to_bool(_ mc: CBOR?) -> Bool? {
    guard let c = mc else {
        return nil
    }
    
    switch c {
    case .unsignedInt(let x):
        return x > 0
    case .negativeInt(let x):
        return (x+1) > 0
    case .boolean(let x):
        return x
    case .half(let x):
        return x > 0.0
    case .float(let x):
        return x > 0.0
    case .double(let x):
        return x > 0.0
    default:
        return nil
    }
}


func force_to_int64(_ c: CBOR) -> Int64 {
    if case let CBOR.negativeInt(x) = c {
        return Int64(x) + 1
    }
    if case let CBOR.unsignedInt(x) = c {
        return Int64(x)
    }
    return 0
}

struct NooID : Codable, Equatable, Hashable {
    var slot: UInt32
    var gen : UInt32
    
    static var NULL = NooID(s: UInt32.max, g: UInt32.max)
    
    init(s: UInt32, g: UInt32) {
        slot = s
        gen = g
    }
    
    init?(_ cbor: CBOR) {
        guard case let CBOR.array(arr) = cbor else {
            return nil
        }
        
        if arr.count < 2 {
            return nil
        }
        
        let check_s = force_to_int64(arr[0])
        let check_g = force_to_int64(arr[1])
        
        // if it outside of a u32, explode. Null is still valid
        if check_s > UInt32.max || check_g > UInt32.max {
            return nil
        }
        
        if check_s < 0 || check_g < 0 {
            return nil
        }

        slot = UInt32(check_s)
        gen  = UInt32(check_g)
    }
    
    func is_valid() -> Bool {
        return slot < UInt32.max && gen < UInt32.max
    }
}

//


struct IntroductionMessage : NoodlesMessage {
    static var message_id: Int = 0
    
    var client_name : String = ""
    
    func to_cbor() -> CBOR {
        return [
            "client_name" : CBOR.utf8String(client_name)
        ]
    }
}

//

struct MsgMethodCreate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgMethodCreate()
    }
}
struct MsgSignalCreate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgSignalCreate()
    }
}


struct RenderRep {
    /*
     mesh : GeometryID,
     ? instances : InstanceSource,
     */
    
    var mesh: NooID
    
    init?(_ mc: CBOR?) {
        guard let c = mc else {
            return nil
        }
        
        mesh = to_id(c["mesh"]) ?? NooID.NULL
    }
}

struct MsgEntityCreate : NoodlesServerMessage {
    /*
     id : EntityID,
         ? name : tstr

         ? parent : EntityID,
         ? transform : Mat4,
         
         ; ONE OF
         ? text_rep : TextRepresentation //
         ? web_rep  : WebRepresentation //
         ? render_rep : RenderRepresentation,
         ; END ONE OF

         ? lights : [* LightID],
         ? tables : [* TableID],
         ? plots : [* PlotID],
         ? tags : [* tstr],
         ? methods_list : [* MethodID],
         ? signals_list : [* SignalID],

         ? influence : BoundingBox,
         ? visible : bool, ; default to true
     */
    
    var id = NooID.NULL
    var name = ""
    var parent = NooID.NULL
    var tf = matrix_identity_float4x4
    var rep : RenderRep?
    
    var lights : [NooID] = []
    var tables : [NooID] = []
    var plots : [NooID] = []
    var tags : [String] = []
    var methods_list : [NooID] = []
    var signals_list : [NooID] = []
    var visible = true
    
    
    static func from_cbor(c: CBOR) -> Self {
        var ret = MsgEntityCreate()
        
        ret.id = to_id(c["id"]) ?? NooID.NULL
        ret.name = to_string(c["name"]) ?? ""
        ret.parent = to_id(c["parent"]) ?? NooID.NULL
                
        ret.tf = to_mat4(c["transform"]) ?? matrix_identity_float4x4
        
        ret.rep = RenderRep(c["render_rep"])
        
        return ret
    }
}
struct MsgEntityUpdate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgEntityUpdate()
    }
}
struct MsgPlotCreate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgPlotCreate()
    }
}
struct MsgPlotUpdate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgPlotUpdate()
    }
}
struct MsgBufferCreate : NoodlesServerMessage {
    var id = NooID.NULL
    var size: Int64 = 0
    var bytes: Data = Data()
    
    static func from_cbor(c: CBOR) -> Self {
        guard case let CBOR.map(m) = c else {
            return MsgBufferCreate()
        }
        
        var ret = MsgBufferCreate()
        /*
         id : BufferID,
             ? name : tstr,
             size : uint,

             ; ONE OF
             inline_bytes : bytes //
             uri_bytes : Location,
             ; END ONE OF
         */
        ret.id = to_id(c["id"]) ?? NooID.NULL
        
        if let sz = m["size"] {
            ret.size = to_int64(sz) ?? 0
        }
        
        if let iline = m["inline_bytes"] {
            if case let CBOR.byteString(array) = iline {
                ret.bytes = Data(array)
            }
        }
        
        if let oline = m["uri_bytes"] {
            if let dl = try? Data(contentsOf: URL(string: to_string(oline))!) {
                ret.bytes = dl
            }
        }
        
        return ret
    }
}
struct MsgBufferViewCreate : NoodlesServerMessage {
    var id = NooID.NULL
    var source_buffer = NooID.NULL
    var offset = Int64(0)
    var length = Int64(0)
    static func from_cbor(c: CBOR) -> Self {
        var ret = MsgBufferViewCreate()
        /*
         id : BufferViewID,
             ? name : tstr,
             source_buffer : BufferID,

             type : "UNK" / "GEOMETRY" / "IMAGE",
             offset : uint,
             length : uint,
         */
        ret.id = NooID(c["id"]!)!
        ret.source_buffer = NooID(c["source_buffer"]!)!
        ret.offset = to_int64(c["offset"]) ?? 0
        ret.length = to_int64(c["length"]) ?? 0
        return ret
    }
}

func to_color(_ c: CBOR?) -> UIColor? {
    guard let arr = to_float_array(c) else {
        return nil
    }
    
    dump(arr)
    
    var r : CGFloat = 1.0
    var g : CGFloat = 1.0
    var b : CGFloat = 1.0
    var a : CGFloat = 1.0
    
    if arr.count >= 3 {
        r = CGFloat(arr[0])
        g = CGFloat(arr[1])
        b = CGFloat(arr[2])
    }
    
    if arr.count >= 4 {
        a = CGFloat(arr[3])
    }
    
    return UIColor(red: r, green: g, blue: b, alpha: a)
}

struct PBRInfo {
    /*
     base_color : RGBA, ; Default is all white
    ? base_color_texture : TextureRef, ; Assumed to be SRGB, no premult alpha

    ? metallic : float, ; assume 1 by default
    ? roughness : float, ; assume 1 by default
    ? metal_rough_texture : TextureRef, ; Assumed to be linear, ONLY RG used
     */
    var base_color: UIColor = .white
    var metallic: Float = 1.0
    var roughness: Float = 1.0
    
    init() {
        
    }
    
    init?(_ mc: CBOR?) {
        guard let c = mc else {
            return nil
        }
        base_color = to_color(c["base_color"]) ?? .white
        metallic = to_float(c["metallic"]) ?? 1.0
        roughness = to_float(c["roughness"]) ?? 1.0
    }
}

struct MsgMaterialCreate : NoodlesServerMessage {
    /*
     id : MaterialID,
     ? name : tstr,

     ? pbr_info : PBRInfo, ; if missing, defaults
     ? normal_texture : TextureRef,
     
     ? occlusion_texture : TextureRef, ; assumed to be linear, ONLY R used
     ? occlusion_texture_factor : float, ; assume 1 by default

     ? emissive_texture : TextureRef, ; assumed to be SRGB. ignore A.
     ? emissive_factor  : Vec3, ; all 1 by default

     ? use_alpha    : bool,  ; false by default
     ? alpha_cutoff : float, ; .5 by default

     ? double_sided : bool, ; false by default
     */
    var id = NooID.NULL
    var pbr_info = PBRInfo()
    
    static func from_cbor(c: CBOR) -> Self {
        var ret = MsgMaterialCreate()
        
        ret.id = NooID(c["id"]!)!
        ret.pbr_info = PBRInfo(c["pbr_info"]) ?? PBRInfo()
        
        return ret
    }
}

struct MsgMaterialUpdate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgMaterialUpdate()
    }
}
struct MsgImageCreate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgImageCreate()
    }
}
struct MsgTextureCreate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgTextureCreate()
    }
}
struct MsgSamplerCreate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgSamplerCreate()
    }
}
struct MsgLightCreate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgLightCreate()
    }
}
struct MsgLightUpdate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgLightUpdate()
    }
}

struct GeomAttrib {
    /*
     AttributeSemantic =
         "POSITION" / ; for the moment, must be a vec3.
         "NORMAL" /   ; for the moment, must be a vec3.
         "TANGENT" /  ; for the moment, must be a vec3.
         "TEXTURE" /  ; for the moment, is either a vec2, or normalized u16vec2
         "COLOR"      ; normalized u8vec4, or vec4

     Attribute = {
         view : BufferViewID,
         semantic : AttributeSemantic,
         ? channel : uint,
         ? offset : uint, ; default 0
         ? stride : uint, ; default 0
         format : Format,
         ? minimum_value : [* float],
         ? maximum_value : [* float],
         ? normalized : bool, ; default false
     }
     */
    
    var view : NooID
    var semantic : String
    var channel : Int64
    var offset : Int64
    var stride : Int64
    var format : String
    var minimum_value : Array<Float>
    var maximum_value : Array<Float>
    var normalized : Bool
    
    init(_ c: CBOR) {
        view = to_id(c["view"]) ?? NooID.NULL
        semantic = to_string(c["semantic"]) ?? "POSITION"
        channel = to_int64(c["channel"]) ?? 0
        offset = to_int64(c["offset"]) ?? 0
        stride = to_int64(c["stride"]) ?? 0
        format = to_string(c["format"]) ?? "VEC3"
        
        minimum_value = []
        maximum_value = []
        
        if case let Optional<CBOR>.some(CBOR.array(arr)) = c["minimum_value"] {
            for att in arr {
                minimum_value.append(to_float(att) ?? 0.0)
            }
        }
        
        if case let Optional<CBOR>.some(CBOR.array(arr)) = c["maximum_value"] {
            for att in arr {
                maximum_value.append(to_float(att) ?? 0.0)
            }
        }
        
        normalized = to_bool(c["normalized"]) ?? false
    }
}

struct GeomIndex {
    /*
     Index = {
         view : BufferViewID,
         count : uint,
         ? offset : uint, ; default 0
         ? stride : uint,; default 0
         format : Format,; only U8, U16, and U32 are accepted
     }
     */
    
    var view: NooID
    var count: Int64
    var offset: Int64
    var stride: Int64
    var format: String
    
    init(_ c: CBOR) {
        view = to_id(c["view"]) ?? NooID.NULL
        count = to_int64(c["count"]) ?? 0
        offset = to_int64(c["offset"]) ?? 0
        stride = to_int64(c["stride"]) ?? 0
        format = to_string(c["format"]) ?? "U32"
    }
}

struct GeomPatch {
    /*
     PrimitiveType = "POINTS"/
                     "LINES"/
                     "LINE_LOOP"/
                     "LINE_STRIP"/
                     "TRIANGLES"/
                     "TRIANGLE_STRIP"
     
     GeometryPatch = {
         attributes   : [ + Attribute ],
         vertex_count : uint,
         ? indices   : Index, ; if missing, non indexed primitives only
         type : PrimitiveType,
         material : MaterialID,
     }
     */
    
    var attributes : Array<GeomAttrib>
    var vertex_count : Int64
    var indices : GeomIndex?
    var type : String
    var material : NooID
    
    init(_ c: CBOR) {
        vertex_count = to_int64(c["vertex_count"]) ?? 0
        type = to_string(c["type"]) ?? "TRIANGLES"
        material = to_id(c["material"]) ?? NooID.NULL
        
        attributes = []
        
        if case let Optional<CBOR>.some(CBOR.array(arr)) = c["attributes"] {
            for att in arr {
                attributes.append(GeomAttrib(att))
            }
        }
        
        if case let Optional<CBOR>.some(idx) = c["indices"] {
            indices = GeomIndex(idx)
        }
    }
}

struct MsgGeometryCreate : NoodlesServerMessage {
    /*
     MsgGeometryCreate = {
         id : GeometryID,
         ? name : tstr,
         patches : [+ GeometryPatch],
     }
     */
    
    var id = NooID.NULL
    var name = String()
    var patches : Array<GeomPatch> = []
    
    static func from_cbor(c: CBOR) -> Self {
        var ret = MsgGeometryCreate()
        
        ret.id = NooID(c["id"]!)!
        
        if case let Optional<CBOR>.some(CBOR.array(arr)) = c["patches"] {
            for att in arr {
                ret.patches.append(GeomPatch(att))
            }
        }
        
        return ret
    }
}
struct MsgTableCreate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgTableCreate()
    }
}
struct MsgTableUpdate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgTableUpdate()
    }
}
struct MsgDocumentUpdate : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgDocumentUpdate()
    }
}
struct MsgDocumentReset : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgDocumentReset()
    }
}
struct MsgSignalInvoke : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgSignalInvoke()
    }
}
struct MsgMethodReply : NoodlesServerMessage  {
    static func from_cbor(c: CBOR) -> Self {
        return MsgMethodReply()
    }
}
struct MsgDocumentInitialized : NoodlesServerMessage {
    static func from_cbor(c: CBOR) -> Self {
        return MsgDocumentInitialized()
    }
}

struct MsgCommonDelete {
    var id : NooID
    static func from_cbor(c: CBOR) -> Self {
        let id = NooID(c["id"]!)!
        return MsgCommonDelete(id: id)
    }
}

enum FromServerMessage {
    case method_create(MsgMethodCreate)
    case method_delete(MsgCommonDelete)
    case signal_create(MsgSignalCreate)
    case signal_delete(MsgCommonDelete)
    case entity_create(MsgEntityCreate)
    case entity_update(MsgEntityUpdate)
    case entity_delete(MsgCommonDelete)
    case plot_create(MsgPlotCreate)
    case plot_update(MsgPlotUpdate)
    case plot_delete(MsgCommonDelete)
    case buffer_create(MsgBufferCreate)
    case buffer_delete(MsgCommonDelete)
    case buffer_view_create(MsgBufferViewCreate)
    case buffer_view_delete(MsgCommonDelete)
    case material_create(MsgMaterialCreate)
    case material_update(MsgMaterialUpdate)
    case material_delete(MsgCommonDelete)
    case image_create(MsgImageCreate)
    case image_delete(MsgCommonDelete)
    case texture_create(MsgTextureCreate)
    case texture_delete(MsgCommonDelete)
    case sampler_create(MsgSamplerCreate)
    case sampler_delete(MsgCommonDelete)
    case light_create(MsgLightCreate)
    case light_update(MsgLightUpdate)
    case light_delete(MsgCommonDelete)
    case geometry_create(MsgGeometryCreate)
    case geometry_delete(MsgCommonDelete)
    case table_create(MsgTableCreate)
    case table_update(MsgTableUpdate)
    case table_delete(MsgCommonDelete)
    case document_update(MsgDocumentUpdate)
    case document_reset(MsgDocumentReset)
    case signal_invoke(MsgSignalInvoke)
    case method_reply(MsgMethodReply)
    case document_initialized(MsgDocumentInitialized)
}

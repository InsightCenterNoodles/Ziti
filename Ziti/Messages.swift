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

class DecodeInfo {
    var current_host: String
    
    init(_ h: String) {
        current_host = h
    }
}

protocol NoodlesMessage {
    static var message_id: Int { get }
    
    func to_cbor() -> CBOR
}

private protocol NoodlesServerMessage {
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self
}

var default_log = Logger()

struct MessageDecoder {
    
    let dec_info: DecodeInfo
    
    init(current_host : String) {
        dec_info = DecodeInfo(current_host)
    }
    
    private func decode_single(mid: CBOR, content: CBOR) -> FromServerMessage? {
        
        switch to_int64(mid)  {
        case 0 :
            return FromServerMessage.method_create(MsgMethodCreate.from_cbor(c: content, info: dec_info))
        case  1 :
            return FromServerMessage.method_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  2 :  return FromServerMessage.signal_create(MsgSignalCreate.from_cbor(c: content, info: dec_info))
        case  3 :  return FromServerMessage.signal_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  4 :  return FromServerMessage.entity_create(MsgEntityCreate.from_cbor(c: content, info: dec_info))
        case  5 :  return FromServerMessage.entity_update(MsgEntityCreate.from_cbor(c: content, info: dec_info))
        case  6 :  return FromServerMessage.entity_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  7 :  return FromServerMessage.plot_create(MsgPlotCreate.from_cbor(c: content, info: dec_info))
        case  8 :  return FromServerMessage.plot_update(MsgPlotUpdate.from_cbor(c: content, info: dec_info))
        case  9 :  return FromServerMessage.plot_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  10 :  return FromServerMessage.buffer_create(MsgBufferCreate.from_cbor(c: content, info: dec_info))
        case  11 :  return FromServerMessage.buffer_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  12 :  return FromServerMessage.buffer_view_create(MsgBufferViewCreate.from_cbor(c: content, info: dec_info))
        case  13 :  return FromServerMessage.buffer_view_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  14 :  return FromServerMessage.material_create(MsgMaterialCreate.from_cbor(c: content, info: dec_info))
        case  15 :  return FromServerMessage.material_update(MsgMaterialUpdate.from_cbor(c: content, info: dec_info))
        case  16 :  return FromServerMessage.material_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  17 :  return FromServerMessage.image_create(MsgImageCreate.from_cbor(c: content, info: dec_info))
        case  18 :  return FromServerMessage.image_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  19 :  return FromServerMessage.texture_create(MsgTextureCreate.from_cbor(c: content, info: dec_info))
        case  20 :  return FromServerMessage.texture_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  21 :  return FromServerMessage.sampler_create(MsgSamplerCreate.from_cbor(c: content, info: dec_info))
        case  22 :  return FromServerMessage.sampler_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  23 :  return FromServerMessage.light_create(MsgLightCreate.from_cbor(c: content, info: dec_info))
        case  24 :  return FromServerMessage.light_update(MsgLightUpdate.from_cbor(c: content, info: dec_info))
        case  25 :  return FromServerMessage.light_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  26 :  return FromServerMessage.geometry_create(MsgGeometryCreate.from_cbor(c: content, info: dec_info))
        case  27 :  return FromServerMessage.geometry_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  28 :  return FromServerMessage.table_create(MsgTableCreate.from_cbor(c: content, info: dec_info))
        case  29 :  return FromServerMessage.table_update(MsgTableUpdate.from_cbor(c: content, info: dec_info))
        case  30 :  return FromServerMessage.table_delete(MsgCommonDelete.from_cbor(c: content, info: dec_info))
        case  31 :  return FromServerMessage.document_update(MsgDocumentUpdate.from_cbor(c: content, info: dec_info))
        case  32 :  return FromServerMessage.document_reset(MsgDocumentReset.from_cbor(c: content, info: dec_info))
        case  33 :  return FromServerMessage.signal_invoke(MsgSignalInvoke.from_cbor(c: content, info: dec_info))
        case  34 :  return FromServerMessage.method_reply(MsgMethodReply.from_cbor(c: content, info: dec_info))
        case  35 :  return FromServerMessage.document_initialized(MsgDocumentInitialized.from_cbor(c: content, info: dec_info))
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
            
            guard let msg = decode_single(mid: mid, content: content) else {
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

struct PartialLocation {
    var scheme : String
    var host : String?
    var port : Int64?
    var path : String?
    
    func to_url(current_host: String?) -> URL? {
        let real_host = (current_host ?? self.host) ?? ""
        
        var s = "\(scheme)://\(real_host)"
        
        if let p = self.port {
            s += ":\(p)"
        }
        
        s += "/"
        
        if let p = self.path {
            s += "/\(p)"
        }
        
        return URL(string: s)
    }
}

enum Location {
    case Link(String)
    case Partial(PartialLocation)
}

extension Location {
    func to_url(current_host: String?) -> URL? {
        switch self {
        case .Link(let x):
            return URL(string: x)
        case .Partial(let x):
            return x.to_url(current_host: current_host)
        }
    }
}

func to_location(_ mc: CBOR?) -> Location? {
    guard let c = mc else {
        return nil
    }
    if case let CBOR.utf8String(x) = c {
        return Location.Link(x)
    } else {
        let pl = PartialLocation(
            scheme: to_string(c["sceme"]) ?? "ws",
            host: to_string(c["host"]),
            port: to_int64(c["port"]) ?? 50001,
            path: to_string(c["path"])
        )
        return Location.Partial(pl)
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

func to_mat3(_ mc: CBOR?) -> simd_float3x3? {
    guard let arr = to_float_array(mc) else {
        return nil
    }
    
    if arr.count < 9 {
        return nil
    }
    
    
    return simd_float3x3(SIMD3<Float>(arr[0...2]),
                  SIMD3<Float>(arr[3...5]),
                  SIMD3<Float>(arr[6...8]));
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

func to_vec3(_ mc: CBOR?) -> simd_float3? {
    guard let arr = to_float_array(mc) else {
        return nil
    }
    
    if arr.count < 3 {
        return nil
    }
    
    return simd_float3(arr[0...2]);
}

struct BB {
    var min: simd_float3
    var max: simd_float3
}

func to_bb(_ mc: CBOR?) -> BB? {
    /*
     BoundingBox = {
         min : Vec3,
         max : Vec3,
     }
     */
    guard let c = mc else {
        return nil
    }
    
    let min = to_vec3(c["min"])!
    let max = to_vec3(c["max"])!
    
    return BB(min: min, max: max)
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
    
    func to_cbor() -> CBOR {
        return [slot.toCBOR(), gen.toCBOR()]
    }
    
    static func array_from_cbor(_ cbor: CBOR?) -> [NooID]? {
        guard let ex = cbor else {
            return nil
        }
        guard case let CBOR.array(arr) = ex else {
            return nil
        }
        
        return arr.compactMap({ f in NooID(f) });
    }
}

// ==


struct IntroductionMessage : NoodlesMessage {
    static var message_id: Int = 0
    
    var client_name : String = ""
    
    func to_cbor() -> CBOR {
        return [
            "client_name" : CBOR.utf8String(client_name)
        ]
    }
}

enum InvokeMessageOn {
case Document
case Entity(NooID)
}

struct InvokeMethodMessage : NoodlesMessage {
    static var message_id: Int = 1
    
    var method : NooID
    var context : InvokeMessageOn
    var invoke_id : String?
    
    var args = [CBOR]()
    
    func to_cbor() -> CBOR {
        var c : CBOR = [
            "method" : method.to_cbor(),
            "args" : args.toCBOR(),
        ]
        
        if let inv = invoke_id {
            c["invoke_id"] = CBOR.utf8String(inv)
        }
        
        if case let InvokeMessageOn.Entity(nooID) = context {
            c["context"] = [ "entity" : nooID.to_cbor() ]
        }
        
        return c
    }
}

// ==

struct MethodArg : Hashable {
    var name : String
    var doc : String?
    var editor_hint : String?
    
    static func from_cbor(c: CBOR?, info: DecodeInfo) -> [Self] {
        if c == nil { return [] }
        guard case let CBOR.array(list) = c! else {
            return []
        }
        
        var ret = [Self]()
        
        for l in list {
            let aname = to_string(l["name"]) ?? "UNKNOWN"
            let adoc = to_string(l["doc"])
            let hint = to_string(l["hint"])
            ret.append(MethodArg(name: aname, doc: adoc, editor_hint: hint))
        }
        
        return ret
    }
}

struct MsgMethodCreate : NoodlesServerMessage, Hashable {
    var id : NooID
    var name : String
    var doc : String?
    var return_doc : String?
    var arg_doc : [MethodArg]
    
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        let id = to_id(c["id"]) ?? NooID.NULL
        let name = to_string(c["name"]) ?? ""
        let doc = to_string(c["doc"])
        let return_doc = to_string(c["return_doc"])
        let arg_doc = MethodArg.from_cbor(c: c["arg_doc"], info: info)
        
        return MsgMethodCreate(id: id, name: name, doc: doc, return_doc: return_doc, arg_doc: arg_doc)
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
        hasher.combine(doc)
        hasher.combine(return_doc)
        hasher.combine(arg_doc)
    }
}
struct MsgSignalCreate : NoodlesServerMessage {
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        return MsgSignalCreate()
    }
}

struct InstanceSource {
    /*
     InstanceSource = {
         ; this is a view of mat4.
         view : BufferViewID,

         ; bytes between instance matrices. For best performance, there should be
         ; no padding. If missing, assume tightly packed.
         ? stride : uint,

         ? bb : BoundingBox,
     }
     */
    
    var view : NooID
    var stride: Int64
    var bb : BB?
    
    init?(_ mc: CBOR?) {
        guard let c = mc else {
            return nil
        }
        
        view = to_id(c["view"]) ?? NooID.NULL
        stride = to_int64(c["stride"]) ?? 0
        bb = to_bb(c["bb"])
    }
}

struct RenderRep {
    /*
     mesh : GeometryID,
     ? instances : InstanceSource,
     */
    
    var mesh: NooID
    
    var instances: InstanceSource?
    
    init?(_ mc: CBOR?) {
        guard let c = mc else {
            return nil
        }
        
        mesh = to_id(c["mesh"]) ?? NooID.NULL
        instances = InstanceSource(c["instances"])
    }
}

struct NullRep {
    init?(_ mc: CBOR?) {
        guard let _ = mc else {
            return nil
        }
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
    
    var id : NooID
    var name : String?
    var parent : NooID?
    var tf : simd_float4x4?
    var null_rep: NullRep?
    var rep : RenderRep?
    
    var lights : [NooID]? = []
    var tables : [NooID]? = []
    var plots : [NooID]? = []
    var tags : [String]? = []
    var methods_list : [NooID]? = []
    var signals_list : [NooID]? = []
    var visible : Bool? = true
    
    
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        let id = to_id(c["id"]) ?? NooID.NULL
        let name = to_string(c["name"]) ?? ""
        
        var ret = MsgEntityCreate(id: id, name: name)

        ret.parent = to_id(c["parent"])
                
        ret.tf = to_mat4(c["transform"])
        
        ret.null_rep = NullRep(c["null_rep"])
        ret.rep = RenderRep(c["render_rep"])
        
        ret.methods_list = NooID.array_from_cbor(c["methods_list"])
        
        return ret
    }
}
//struct MsgEntityUpdate : NoodlesServerMessage {
//    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
//        return MsgEntityUpdate()
//    }
//}
struct MsgPlotCreate : NoodlesServerMessage {
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        return MsgPlotCreate()
    }
}
struct MsgPlotUpdate : NoodlesServerMessage {
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        return MsgPlotUpdate()
    }
}
struct MsgBufferCreate : NoodlesServerMessage {
    var id = NooID.NULL
    var size: Int64 = 0
    var bytes: Data = Data()
    
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
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
        
        if let oline = to_location(m["uri_bytes"]) {
            let real_loc = oline.to_url(current_host: info.current_host)
            if let dl = try? Data(contentsOf: real_loc!) {
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
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
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
    
    //dump(arr)
    
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

struct TexRef {
    /*
     TextureRef = {
         texture : TextureID,
         ? transform : Mat3, ; if missing assume identity
         ? texture_coord_slot : uint, ; if missing, assume 0
     }
     */
    var texture : NooID = NooID.NULL
    var transform: simd_float3x3 = matrix_identity_float3x3
    var texture_coord_slot: Int16 = 0
    
    init() {
    }
    
    init?(_ mc: CBOR?) {
        guard let c = mc else {
            return nil
        }
        texture = to_id(c["texture"]) ?? NooID.NULL
        transform = to_mat3(c["transform"]) ?? matrix_identity_float3x3
        texture_coord_slot = Int16(to_int64(c["texture_coord_slot"]) ?? Int64(1.0))
    }
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
    var base_color_texture: TexRef?
    var metallic: Float = 1.0
    var roughness: Float = 1.0
    
    init() {
    }
    
    init?(_ mc: CBOR?) {
        guard let c = mc else {
            return nil
        }
        base_color = to_color(c["base_color"]) ?? .white
        base_color_texture = TexRef(c["base_color_texture"])
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
    var id : NooID
    var pbr_info : PBRInfo
    var normal_texture : TexRef?
    
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        
        let id = NooID(c["id"]!)!
        let pbr_info = PBRInfo(c["pbr_info"]) ?? PBRInfo()
        let normal_texture = TexRef(c["normal_texture"])
        
        return MsgMaterialCreate(id: id, pbr_info: pbr_info, normal_texture: normal_texture)
    }
}

struct MsgMaterialUpdate : NoodlesServerMessage {
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        return MsgMaterialUpdate()
    }
}
struct MsgImageCreate : NoodlesServerMessage {
    /*
     id : ImageID,
     ? name : tstr,

     ; ONE OF
     (
         buffer_source : BufferViewID //
         uri_source : Location
     ),
     ; END ONE OF
     */
    
    var id : NooID
    var buffer_source : NooID?
    var saved_bytes : Data?
    
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        
        let id = NooID(c["id"]!)!
        
        let buffer_source = to_id(c["buffer_source"])
        
        let saved_bytes = c["uri_source"]
            .map({ to_location($0) })?
            .map({ $0.to_url(current_host: info.current_host) })?
            .map({ (try? Data(contentsOf: $0))! })
        
        return MsgImageCreate(id: id, buffer_source: buffer_source, saved_bytes: saved_bytes )
    }
}
struct MsgTextureCreate : NoodlesServerMessage {
    /*
     id : TextureID,
     ? name : tstr,
     image : ImageID,
     ? sampler : SamplerID, ; if missing use a default sampler
     */
    
    var id : NooID
    var image_id : NooID
    var sampler_id : NooID?
    
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        
        let id = NooID(c["id"]!)!
        let image_id = to_id(c["image"]) ?? NooID.NULL
        let sampler_id = to_id(c["sampler"]) ?? NooID.NULL
        
        return MsgTextureCreate(
            id: id,
            image_id: image_id,
            sampler_id: sampler_id
        )
    }
}
struct MsgSamplerCreate : NoodlesServerMessage {
    /*
     id : SamplerID,
     ? name : tstr,
     
     ? mag_filter : "NEAREST" / "LINEAR", ; default is LINEAR
     ? min_filter : MinFilters, ; default is LINEAR_MIPMAP_LINEAR

     ? wrap_s : SamplerMode, ; default is REPEAT
     ? wrap_t : SamplerMode, ; default is REPEAT
     */
    
    var id : NooID
    var mag_filter : String
    var min_filter : String
    
    var wrap_s : String
    var wrap_t : String
    
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        let id = to_id(c["id"])!
        let mag = to_string(c["mag_filter"]) ?? "LINEAR"
        let min = to_string(c["min_filter"]) ?? "LINEAR_MIPMAP_LINEAR"
        let ws = to_string(c["wrap_s"]) ?? "REPEAT"
        let wt = to_string(c["wrap_t"]) ?? "REPEAT"
        return MsgSamplerCreate(
            id: id, mag_filter: mag, min_filter: min, wrap_s: ws, wrap_t: wt
        )
    }
}
struct MsgLightCreate : NoodlesServerMessage {
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        return MsgLightCreate()
    }
}
struct MsgLightUpdate : NoodlesServerMessage {
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
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
    
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
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
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        return MsgTableCreate()
    }
}
struct MsgTableUpdate : NoodlesServerMessage {
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        return MsgTableUpdate()
    }
}
struct MsgDocumentUpdate : NoodlesServerMessage {
    /*
     ? methods_list : [* MethodID],
     ? signals_list : [* SignalID],
     */
    
    var methods_list : [NooID]?
    var signals_list : [NooID]?
    
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        let mlist = NooID.array_from_cbor(c["methods_list"])
        let slist = NooID.array_from_cbor(c["signals_list"])
        return MsgDocumentUpdate(methods_list: mlist, signals_list: slist)
    }
}
struct MsgDocumentReset : NoodlesServerMessage {
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        return MsgDocumentReset()
    }
}
struct MsgSignalInvoke : NoodlesServerMessage {
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        return MsgSignalInvoke()
    }
}

struct MethodReplyException {
    var code: Int64
    var message: String?
    var data: CBOR?
    
    init?(_ mc : CBOR?) {
        guard let c = mc else { return nil }
        
        code = to_int64(c["code"]) ?? -1000000
        message = to_string(c["message"])
        data = c["data"]
    }
}

struct MsgMethodReply : NoodlesServerMessage  {
    /*
     MethodException = {
         code : int,
         ? message : text,
         ? data : any,
     }

     MsgMethodReply = {
         invoke_id : text,
         ? result : any,
         ? method_exception : MethodException,
     }
     */
    
    var invoke_id : String
    var result : CBOR?
    var method_exception: MethodReplyException?
    
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        return MsgMethodReply(
            invoke_id: to_string(c["invoke_id"]) ?? "UNKNOWN",
            result: c["result"],
            method_exception: MethodReplyException(c["method_exception"])
        )
    }
}
struct MsgDocumentInitialized : NoodlesServerMessage {
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
        return MsgDocumentInitialized()
    }
}

struct MsgCommonDelete {
    var id : NooID
    static func from_cbor(c: CBOR, info: DecodeInfo) -> Self {
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
    case entity_update(MsgEntityCreate)
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

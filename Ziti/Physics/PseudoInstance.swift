//
//  PseudoInstance.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 7/12/24.
//

import Foundation
import RealityFoundation
import Metal


extension ParticleVertex {
    static var attributes : [LowLevelMesh.Attribute] = [
        .init(semantic: .position, format: .float3, offset: MemoryLayout<ParticleVertex>.offset(of: \ParticleVertex.position)!),
        .init(semantic: .normal, format: .float3, offset: MemoryLayout<ParticleVertex>.offset(of: \ParticleVertex.normal)!),
        .init(semantic: .uv0, format: .ushort2, offset: MemoryLayout<ParticleVertex>.offset(of: \ParticleVertex.uv)!)
    ]
    
    static var layouts : [LowLevelMesh.Layout] = [
        .init(bufferIndex: 0, bufferOffset: 0, bufferStride: MemoryLayout<ParticleVertex>.stride)
    ]
}

struct GlyphDescription {
    var vertex: [ParticleVertex]
    var index : [ushort]
    var bounding_box: BoundingBox
}


class GlyphInstances {
    var glyph: GlyphDescription
    var low_level_mesh: LowLevelMesh
    var instances: [float4x4]
    let instances_byte_count: Int
    
    var instance_buffer: MTLBuffer
    
    var vertex_pipeline_state: MTLComputePipelineState
    var index_pipeline_state: MTLComputePipelineState
    
    var capture_bounds: MTLCaptureScope
    
    init(instance_count: Int32, description: GlyphDescription) {
        print("Creating instance system")
        let md = LowLevelMesh.Descriptor(vertexCapacity: Int(instance_count) * description.vertex.count,
                                         vertexAttributes: ParticleVertex.attributes,
                                         vertexLayouts: ParticleVertex.layouts,
                                         indexCapacity: Int(instance_count) * description.index.count,
                                         indexType: .uint32)
        glyph = description
        low_level_mesh = try! LowLevelMesh(descriptor: md)
        print("Built LLM")
        instances = .init(repeating: float4x4(), count: Int(instance_count))
        print("Built fixed cpu instance buffer")
        instances_byte_count = Int(instance_count) * MemoryLayout<float4x4>.stride
        instance_buffer = ComputeContext.shared.device.makeBuffer(length: instances_byte_count, options: .storageModeShared)!
        print("Built fixed gpu instance buffer")
        
        vertex_pipeline_state = ComputeContext.shared.make_construct_from_inst_array_state()
        index_pipeline_state  = ComputeContext.shared.make_construct_from_inst_index_state()
        print("Built pipeline state")
        
        capture_bounds = MTLCaptureManager.shared().makeCaptureScope(device: ComputeContext.shared.device)
        capture_bounds.label = "pseudo_particle"
        
        MTLCaptureManager.shared().defaultCaptureScope = capture_bounds
    }
    
    func update() {
        capture_bounds.begin()
        print("EXEC UPDATE")
        
        for i in 0 ..< instances.count {
            let thing = Float(i) / 10
            instances[i] = float4x4(
                SIMD4<Float>(thing, thing, thing, 0.0), // pos
                SIMD4<Float>(1.0, 1.0, 1.0, 1.0), // col
                SIMD4<Float>(0.0, 0.0, 0.0, 1.0), // rot
                SIMD4<Float>(0.1, 0.1, 0.1, 0.0)  // scale
            )
        }
        
        instance_buffer.contents().copyMemory(from: instances, byteCount: instances_byte_count)
        
        
        print("CHECK")
        var descriptor = InstanceDescriptor(instance_count: uint(instances.count), in_vertex_count: uint(glyph.vertex.count), in_index_count: uint(glyph.index.count))
        
        guard let command_buffer = ComputeContext.shared.command_queue.makeCommandBuffer() else {
            default_log.critical("Unable to obtain command buffer. Skipping instance update.")
            return
        }
        
        guard let encoder = command_buffer.makeComputeCommandEncoder() else {
            default_log.critical("Unable to obtain command buffer encoder. Skipping instance update.")
            return
        }
        
        let vertex_buffer = low_level_mesh.replace(bufferIndex: 0, using: command_buffer)
        
        encoder.setComputePipelineState(vertex_pipeline_state)
        
        encoder.setBytes(&descriptor, length: MemoryLayout.size(ofValue: descriptor), index: 0)
        encoder.setBuffer(instance_buffer, offset: 0, index: 1)
        encoder.setBytes(glyph.vertex, length: MemoryLayout<ParticleVertex>.stride * glyph.vertex.count, index: 2)
        encoder.setBuffer(vertex_buffer, offset: 0, index: 3)
        
        let vertex_threads = MTLSize(width: instances.count, height: 1, depth: 1)
        let threads_per_threadgroup = MTLSize(width: 32, height: 1, depth: 1)
        let dispatch_threads = ComputeContext.shared.get_threadgroups(vertex_threads, threads_per_threadgroup: threads_per_threadgroup)
        
        print("DISPATCH \(dispatch_threads)")
        
        encoder.dispatchThreadgroups(dispatch_threads, threadsPerThreadgroup: threads_per_threadgroup)
        
        print("THREADS DISPATCH")
        
        let new_index_buffer = low_level_mesh.replaceIndices(using: command_buffer)
        
        encoder.setComputePipelineState(index_pipeline_state)
        // redundant load below
        //encoder.setBytes(&descriptor, length: MemoryLayout.size(ofValue: descriptor), index: 0)
        encoder.setBytes(glyph.index, length: MemoryLayout<ushort>.stride * glyph.index.count, index: 1)
        encoder.setBuffer(new_index_buffer, offset: 0, index: 2)
        
        encoder.dispatchThreadgroups(dispatch_threads, threadsPerThreadgroup: threads_per_threadgroup)
        
        // need bounding box
        
        // and then the REPLACE ALL parts for LLM
        
        let bounds = BoundingBox(min: SIMD3<Float>(-4.0, -4.0, -4.0), max: SIMD3<Float>(4.0, 4.0, 4.0))
        
        low_level_mesh.parts.replaceAll([
            LowLevelMesh.Part(indexOffset: 0,
                              indexCount: Int(descriptor.instance_count * descriptor.in_index_count),
                              topology: .triangle,
                              materialIndex: 0,
                              bounds: bounds)
        ])
        
        encoder.endEncoding()
        
        command_buffer.commit()
        
        command_buffer.waitUntilCompleted()
        print("DONE")
        capture_bounds.end()
    }
}

//
//  ComputeContext.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 7/5/24.
//

import Foundation
import Metal

class ComputeContext {

    static let shared = ComputeContext()

    let device: MTLDevice
    let command_queue: MTLCommandQueue
    let library: MTLLibrary

    //var compute_pipelines: [MTLComputePipelineState] = []
    
    let direct_upload_function: MTLFunction
    
    let construct_from_inst_array: MTLFunction
    let construct_inst_index: MTLFunction

    init(device: MTLDevice? = nil, commandQueue: MTLCommandQueue? = nil) {
        guard let device = device ?? MTLCreateSystemDefaultDevice() else {
            fatalError("Unable to build Metal device.")
        }
        guard let commandQueue = commandQueue ?? device.makeCommandQueue() else {
            fatalError("Unable to build command queue for given metal device")
        }
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Unable to find code library")
        }
        self.device = device
        self.command_queue = commandQueue
        self.library = library
        
        self.direct_upload_function = library.makeFunction(name: "direct_upload_vertex")!
        
        self.construct_from_inst_array = library.makeFunction(name: "construct_from_inst_array")!
        self.construct_inst_index = library.makeFunction(name: "construct_inst_index")!
        
        let max_threadgroup_size = device.maxThreadsPerThreadgroup
        print("Max Threadgroup Size: \(max_threadgroup_size)")
    }
    
    func get_threadgroups(_ compute_threads: MTLSize, threads_per_threadgroup: MTLSize) -> MTLSize {
        return MTLSize(
            width: next_multiple_of(value: compute_threads.width, multiple: threads_per_threadgroup.width),
            height: next_multiple_of(value: compute_threads.height, multiple: threads_per_threadgroup.height),
            depth: next_multiple_of(value: compute_threads.depth, multiple: threads_per_threadgroup.depth)
        )
    }
    
    func make_construct_from_inst_array_state() -> MTLComputePipelineState {
        return try! device.makeComputePipelineState(function: construct_from_inst_array)
    }
    
    func make_construct_from_inst_index_state() -> MTLComputePipelineState {
        return try! device.makeComputePipelineState(function: construct_inst_index)
    }
}

private func next_multiple_of(value: Int, multiple: Int) -> Int {
    return multiple * Int(ceil(Double(value)/Double(multiple)))
}

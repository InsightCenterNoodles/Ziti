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
    }
    
//    func test() {
//        var commands = command_queue.makeCommandBuffer()!
//        
//        var command_encoder = commands.makeComputeCommandEncoder()!
//        
//        command_encoder.
//    }

//    func makePipelines() throws {
//        guard let library = device.makeDefaultLibrary() else {
//            throw Error.libraryNotFound
//        }

//        let vertexFunctionName = "update_wave_vertex"
//        guard let vertexFunction = library.makeFunction(name: vertexFunctionName) else {
//            throw Error.functionNotFound(name: vertexFunctionName)
//        }
//        let vertexPipeline = try device.makeComputePipelineState(function: vertexFunction)
//        computePipelines.insert(vertexPipeline, at: PipelineIndex.waveVertexUpdate.rawValue)
//
//        let indexFunctionName = "update_grid_indices"
//        guard let indexFunction = library.makeFunction(name: indexFunctionName) else {
//            throw Error.functionNotFound(name: indexFunctionName)
//        }
//        let indexPipeline = try device.makeComputePipelineState(function: indexFunction)
//        computePipelines.insert(indexPipeline, at: PipelineIndex.gridIndexUpdate.rawValue)
//    }
}

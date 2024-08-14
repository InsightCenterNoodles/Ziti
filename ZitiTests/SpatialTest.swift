//
//  SpatialTest.swift
//  ZitiTests
//
//  Created by Nicholas Brunhart-Lupo on 7/25/24.
//

import Testing
import Foundation
import Accelerate
import RealityFoundation

struct SpatialTest {

    @Test func test_tetra_barycoord() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        
        let start_ta = Tetrahedra(
            a: simd_float3(x: 1, y: 2, z: 1),
            b: simd_float3(x: 3, y: 3, z: 9),
            c: simd_float3(x: 3, y: 6, z: 1),
            d: simd_float3(x: 6, y: 2, z: 1),
            data: simd_float4(x: 10, y: 45, z: 30, w: 22)
        )
        
        let ba = TetrahedraBarycentric(start_ta)
        
        let to_check = [
            (simd_float3(x: 1, y: 2, z: 1), simd_float4(x: 1, y: 0, z: 0, w: 0)),
            (simd_float3(x: 3, y: 3, z: 9), simd_float4(x: 0, y: 1, z: 0, w: 0)),
            (simd_float3(x: 3, y: 6, z: 1), simd_float4(x: 0, y: 0, z: 1, w: 0)),
            (simd_float3(x: 6, y: 2, z: 1), simd_float4(x: 0, y: 0, z: 0, w: 1)),
            (simd_float3(x: 3, y: 3, z: 3), simd_float4(x: 0.337, y: 0.25, z: 0.1875, w: 0.225))
        ]
        
        for (p, res) in to_check {
            let coords = ba.to_coordinates(p)
            print(p, res, coords)
            
            #expect(distance(coords, res) < 0.001)
        }
        
    }
    
    @Test func test_tetra_interpolation() async throws {
        let start_ta = Tetrahedra(
            a: simd_float3(x: 1, y: 2, z: 1),
            b: simd_float3(x: 3, y: 3, z: 9),
            c: simd_float3(x: 3, y: 6, z: 1),
            d: simd_float3(x: 6, y: 2, z: 1),
            data: simd_float4(x: 10, y: 45, z: 30, w: 22)
        )
        
        let ba = TetrahedraBarycentric(start_ta)
        
        let to_check = [
            (simd_float3(x: 1, y: 2, z: 1), 10.0),
            (simd_float3(x: 3, y: 3, z: 9), 45.0),
            (simd_float3(x: 3, y: 6, z: 1), 30.0),
            (simd_float3(x: 6, y: 2, z: 1), 22.0),
            (simd_float3(x: 3, y: 3, z: 3), 25.2)
        ]
        
        for (p, res) in to_check {
            let value = ba.interpolate(p)
            //print(p, res, value)
            
            #expect(abs(Double(value) - res) < 0.001)
        }
    }
    
    @Test func test_tetra_raster() async throws {
        let start_ta = Tetrahedra(
            a: simd_float3(x: 0.22712, y: 1.1534, z: 1.9633),
            b: simd_float3(x: 2.7361, y: 0.31018, z: 2.8201),
            c: simd_float3(x: 2.3955, y: 2.926, z: 2.0641),
            d: simd_float3(x: 2.0626, y: 0.56479, z: 0.12847),
            data: simd_float4(x: 10, y: 45, z: 30, w: 22)
        )
        
        var done = false
        
        
        let array = rasterize_tetra(grid_bounds: BoundingBox(min: .zero, max: .one * 3.0), resolution: 3) {
            if done {
                return nil
            }
            done = true
            return start_ta
        }
        
        let to_check : Set = [
            array.index(at: .init(x:2, y:1, z:1)),
            array.index(at: .init(x:1, y:1, z:2)),
            array.index(at: .init(x:2, y:1, z:2)),
            array.index(at: .init(x:2, y:2, z:2)),
        ]
        
        //dump(array.array)
        
        for (i,v) in array.array.enumerated() {
            if to_check.contains(i) {
                #expect(v > 1.0)
            } else {
                #expect(v < 1.0)
            }
        }
    }

}

//
//  ZitiTests.swift
//  ZitiTests
//
//  Created by Nicholas Brunhart-Lupo on 2/12/24.
//

import XCTest
import simd
@testable import Ziti

class ZitiTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}


class VoxelQueryTests: XCTestCase {

    func testExample() throws {
        let points = [
            Record(point: simd_make_float3(2, 2, 2), item: 10),
            Record(point: simd_make_float3(3, 3, 4), item: 11)
        ]
        
        let min = simd_make_float3(2, 2, 2);
        let max = simd_make_float3(3, 3, 4);
        
        var query = VoxelQuery<Int>(min: min, max: max, max_bin_count: 2)
        
        for point in points {
            let installed = query.install(point)
            XCTAssert(installed)
        }
        
        let c1 = query.collect(a: simd_float3(1.5, 1.5, 1.5), b: simd_float3(2.5, 2.5, 2.5))
        XCTAssert(c1.elementsEqual([ points[0] ]))
        
        let c2 = query.collect(a: simd_float3(2.5, 2.5, 3.5), b: simd_float3(3.5, 3.5, 4.5))
        XCTAssert(c2.elementsEqual([ points[1] ]))
        
        let c3 = query.collect(a: simd_float3(1.5, 1.5, 1.5), b: simd_float3(3.5, 3.5, 3.5))
        XCTAssert(c3.elementsEqual(points))
        
        let c4 = query.collect(a: simd_float3(1, 1, 1), b: simd_float3(4, 4, 4))
        XCTAssert(c4.elementsEqual(points))
        
    }

}

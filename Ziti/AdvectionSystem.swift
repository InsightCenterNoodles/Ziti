//
//  AdvectionSystem.swift
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 5/6/24.
//

import Foundation
import SwiftUI
import RealityKit

/// Advection information for an entity.
struct AdvectionComponent: Component {
    var state : NooAdvectorState
    var line_id : Int
    
    var last_start_index = 0
    var particle_time: Float32
}

func find_end_time(list: [Float32], starting_point: Int, value: Float32) -> Int? {
    //print("Finding end time starting \(starting_point) value \(value)")
    let search_range = list[starting_point...]
    return search_range.firstIndex(where: { $0 > value })
}

func lerp(_ x: Float32, _ x0: Float32, _ x1: Float32, _ y0: SIMD3<Float>, _ y1: SIMD3<Float>) -> SIMD3<Float> {
    return y0 + (x - x0) * (y1 - y0) / (x1 - x0)
}

/// A system that advects particles
struct AdvectionSystem: System {
    static let query = EntityQuery(where: .has(AdvectionComponent.self))

    init(scene: RealityKit.Scene) {}
    
    func schedule_delete(_ e: Entity, _ component: AdvectionComponent?) {
        //print("Schedule delete for \(e)")
        e.removeFromParent()
        component?.state.current_particles -= 1
    }
    
    func handle_entity(e: Entity, context: SceneUpdateContext) {
        guard var component: AdvectionComponent = e.components[AdvectionComponent.self] else {
            schedule_delete(e, nil);
            return
        }
        
        // TODO: NEED TO ADD IN FRAME TIME
        
        // increase time
        let new_time = component.particle_time + 0.00001;
        
        // find the indicies that bracket the time (OPTIMIZE LATER)
        
        // line (will this copy?)
        let line = component.state.lines[component.line_id]
        
        guard let time_array = line.attribs.first else {
            //print("No time array")
            schedule_delete(e, component)
            return
        }
        
        guard let end_index = find_end_time(list: time_array.data, starting_point: component.last_start_index, value: new_time) else {
            //print("No end index")
            schedule_delete(e, component)
            return
        }
        
        let start_index = end_index - 1
        
        if start_index < 0 {
            //print("No start index")
            schedule_delete(e, component)
            return
        }
        
        component.last_start_index = start_index
        
        // sample positions
        let start_p = line.positions[start_index]
        let end_p   = line.positions[end_index]
        
        // sample times
        let start_t = time_array.data[start_index]
        let end_t   = time_array.data[end_index]
        
        // set position
        let pos = lerp(new_time, start_t, end_t, start_p, end_p)
        
        e.position = pos
        
        // record time
        
        component.particle_time = new_time
        
        e.components.set(component)
        
        //print("PUSH \(new_time) \(pos) \(start_p) \(end_p) \(start_t) \(end_t)")
    }

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            handle_entity(e: entity, context: context)
        }
    }
}


struct AdvectionSpawnComponent : Component {
    var state : NooAdvectorState
}

struct AdvectionSpawnSystem: System {
    static let query = EntityQuery(where: .has(AdvectionSpawnComponent.self))

    init(scene: RealityKit.Scene) {}
    
    func schedule_delete(_ e: Entity) {
        e.removeFromParent()
    }
    
    func handle_entity(e: Entity, context: SceneUpdateContext) {
        guard let component: AdvectionSpawnComponent = e.components[AdvectionSpawnComponent.self] else {
            schedule_delete(e);
            return
        }
        
        // spawn one per frame till the max
        
        let st = component.state
        
        //print("Particles \(st.current_particles)")
        
        if st.current_particles >= st.max_particles {
            return
        }
        
        // spawn one
        
        // pick a line?
        
        var selected_line = -1
        var largest_line = 0
        
        for (i, line) in st.lines.enumerated() {
            let p = line.positions.count
            
            if p > largest_line {
                selected_line = i
                largest_line = p
            }
        }
        
        if selected_line < 0 {
            return
        }
        
        var tri_mat = PhysicallyBasedMaterial()
        
        tri_mat.baseColor = PhysicallyBasedMaterial.BaseColor.init(tint: .white)
        
        let new_entity = ModelEntity(mesh: .generateSphere(radius: 0.5), materials: [tri_mat])
        
        new_entity.components.set(AdvectionComponent(state: st, line_id: selected_line, particle_time: 0.0))
        
        e.addChild(new_entity)
        
        st.current_particles += 1
        
        //print("SPAWN")
        
    }

    func update(context: SceneUpdateContext) {
        for entity in context.entities(matching: Self.query, updatingSystemWhen: .rendering) {
            handle_entity(e: entity, context: context)
        }
    }
}

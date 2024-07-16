//
//  InstanceTypes.h
//  Ziti
//
//  Created by Nicholas Brunhart-Lupo on 7/12/24.
//

#pragma once

#include <simd/simd.h>

#ifndef __METAL__
typedef struct { float x; float y; float z; } packed_float3;
typedef unsigned uint;
#endif

// A vertex to be used in the pseudo instance/particle system
struct ParticleVertex {
    packed_float3  position;
    packed_float3  normal;
    packed_ushort2 uv;
};

// Core instance information to be used in the pseudo instance/particle system
struct InstanceDescriptor {
    uint instance_count;
    uint in_vertex_count;
    uint in_index_count;
};

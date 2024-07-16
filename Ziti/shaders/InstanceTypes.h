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
//typedef struct { short u; short v; } packed_ushort2;
typedef unsigned uint;
#endif

struct ParticleVertex {
    packed_float3  position;
    packed_float3  normal;
    packed_ushort2 uv;
};

struct InstanceDescriptor {
    uint instance_count;
    uint in_vertex_count;
    uint in_index_count;
};

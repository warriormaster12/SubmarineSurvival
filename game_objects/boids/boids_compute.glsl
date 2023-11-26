#[compute]
#version 450

layout(local_size_x = 48, local_size_y = 1, local_size_z = 1) in;

struct Boid {
    vec3 position;
    vec3 direction;
    vec3 flockHeading;
	vec3 flockCentre;
	vec3 avoidanceHeading;
	int numFlockmates;
};

layout(set = 0, binding = 0, std430) restrict buffer Buffer {
    Boid boids[];
} my_buffer;

float viewRadius = 2;
float avoidRadius = 1;

void main()
{
    for (int indexB = 0; indexB < 48; indexB ++) {
        if (gl_GlobalInvocationID.x != indexB) {
            Boid boidB = my_buffer.boids[indexB];
            vec3 offset = boidB.position - my_buffer.boids[gl_GlobalInvocationID.x].position;
            float sqrDst = offset.x * offset.x + offset.y * offset.y + offset.z * offset.z;

            if (sqrDst < viewRadius * viewRadius) {
                my_buffer.boids[gl_GlobalInvocationID.x].numFlockmates += 1;
                my_buffer.boids[gl_GlobalInvocationID.x].flockHeading += boidB.direction;
                my_buffer.boids[gl_GlobalInvocationID.x].flockCentre += boidB.position;

                if (sqrDst < avoidRadius * avoidRadius) {
                    my_buffer.boids[gl_GlobalInvocationID.x].avoidanceHeading -= offset / sqrDst;
                }
            }
        }
    }
}

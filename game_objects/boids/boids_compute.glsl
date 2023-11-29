#[compute]
#version 450

layout(local_size_x = 100, local_size_y = 1, local_size_z = 1) in;

struct Boid {
    vec4 position;
    vec4 direction;
    vec4 flockHeading;
	vec4 flockCentre;
	vec4 avoidanceHeadingAndFlockmates;
};

layout(set = 0, binding = 0, std430) restrict buffer Buffer {
    Boid boids[];
} my_buffer;

float viewRadius = 6;
float avoidRadius = 2;


void main()
{
    Boid boidA = my_buffer.boids[gl_GlobalInvocationID.x];

    vec3 _pos = vec3(boidA.position.x, boidA.position.y, boidA.position.z);
    vec3 _dir = vec3(boidA.direction.x, boidA.direction.y, boidA.direction.z);
    vec3 _flockH = vec3(boidA.flockHeading.x, boidA.flockHeading.y, boidA.flockHeading.z);
    vec3 _flockC = vec3(boidA.flockCentre.x, boidA.flockCentre.y, boidA.flockCentre.z);
    vec3 _avoidH = vec3(boidA.avoidanceHeadingAndFlockmates.x, boidA.avoidanceHeadingAndFlockmates.y, boidA.avoidanceHeadingAndFlockmates.z);
    float _flockmates = 0;

    for (int indexB = 0; indexB < 100; indexB ++) {
        if (gl_GlobalInvocationID.x != indexB) {
            Boid boidB = my_buffer.boids[indexB];
            vec3 boidB_pos = vec3(boidB.position.x, boidB.position.y, boidB.position.z);
            vec3 boidB_dir = vec3(boidB.direction.x, boidB.direction.y, boidB.direction.z);

            vec3 offset = boidB_pos - _pos;
            float sqrDst = offset.x * offset.x + offset.y * offset.y + offset.z * offset.z;

            if (sqrDst < viewRadius * viewRadius) {
                _flockmates += 1;
                _flockH += boidB_dir;
                _flockC += boidB_pos;

                if (sqrDst < avoidRadius * avoidRadius) {
                    _avoidH -= offset / sqrDst;
                }
            }
        }
    }

    my_buffer.boids[gl_GlobalInvocationID.x].flockHeading = vec4(_flockH.x, _flockH.y, _flockH.z, 0);
    my_buffer.boids[gl_GlobalInvocationID.x].flockCentre = vec4(_flockC.x, _flockC.y, _flockC.z, 0);
    my_buffer.boids[gl_GlobalInvocationID.x].avoidanceHeadingAndFlockmates = vec4(_avoidH.x, _avoidH.y, _avoidH.z, _flockmates);
}

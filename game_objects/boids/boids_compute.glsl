#[compute]
#version 450

layout(local_size_x = 1, local_size_y = 1, local_size_z = 1) in;

struct Boid {
    vec3 position;
    vec3 direction;
	
    vec3 flockHeading;
	vec3 flockCentre;
	vec3 avoidanceHeading;
	int numFlockmates;
}

layout(set = 0, binding = 0, std430) restrict buffer Buffer {
    Boid boids[];
}
my_buffer;

float viewRadius = 10;
float avoidRadius = 10;

void main()
{
    for (int indexA = 0; indexA < my_buffer.data[6] * 17; indexA += 17) {
        vec3 boidA_pos = vec3(my_buffer.data[indexA], my_buffer.data[indexA+1], my_buffer.data[indexA+2]);
        vec3 boidA_dir = vec3(my_buffer.data[indexA+3], my_buffer.data[indexA+4], my_buffer.data[indexA+5]);
        vec3 boidA_flockHeading = vec3(my_buffer.data[indexA+7], my_buffer.data[indexA+8], my_buffer.data[indexA+9]);
        vec3 boidA_flockCentre = vec3(my_buffer.data[indexA+10], my_buffer.data[indexA+11], my_buffer.data[indexA+12]);
        vec3 boidA_avoidanceHeading = vec3(my_buffer.data[indexA+13], my_buffer.data[indexA+14], my_buffer.data[indexA+15]);

        for (int indexB = 0; indexB < my_buffer.data[6] * 17; indexB += 17) {
            if (indexA != indexB) {
                vec3 boidB_pos = vec3(my_buffer.data[indexB], my_buffer.data[indexB+1], my_buffer.data[indexB+2]);
                vec3 boidB_dir = vec3(my_buffer.data[indexB+3], my_buffer.data[indexB+4], my_buffer.data[indexB+5]);

                vec3 offset = boidB_pos - boidA_pos;
                float sqrDst = offset.x * offset.x + offset.y * offset.y + offset.z * offset.z;

                if (sqrDst < viewRadius * viewRadius) {
                    my_buffer.data[indexA+16] += 1;
                    boidA_flockHeading += boidB_dir;
                    boidA_flockCentre += boidB_pos;

                    if (sqrDst < avoidRadius * avoidRadius) {
                        boidA_avoidanceHeading -= offset / sqrDst;
                    }
                }
            }
        }

        my_buffer.data[indexA] = boidA_pos.x;
        my_buffer.data[indexA+1] = boidA_pos.y;
        my_buffer.data[indexA+2] = boidA_pos.z;
        my_buffer.data[indexA+3] = boidA_dir.x;
        my_buffer.data[indexA+4] = boidA_dir.y;
        my_buffer.data[indexA+5] = boidA_dir.z;
        my_buffer.data[indexA+7] = boidA_flockHeading.x;
        my_buffer.data[indexA+8] = boidA_flockHeading.y;
        my_buffer.data[indexA+9] = boidA_flockHeading.z;
        my_buffer.data[indexA+10] = boidA_flockCentre.x;
        my_buffer.data[indexA+11] = boidA_flockCentre.y;
        my_buffer.data[indexA+12] = boidA_flockCentre.z;
        my_buffer.data[indexA+13] = boidA_avoidanceHeading.x;
        my_buffer.data[indexA+14] = boidA_avoidanceHeading.y;
        my_buffer.data[indexA+15] = boidA_avoidanceHeading.z;
    }
}
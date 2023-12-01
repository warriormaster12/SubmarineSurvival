shader_type spatial;

uniform sampler2D _a;
uniform sampler2D heightmap;
uniform float height_ratio = 1.0;

void vertex() {
	VERTEX.y += texture(heightmap, UV).r * height_ratio;
}

void fragment() {
	ALBEDO = texture(_a, UV*10.0).rgb;
}

void light() {
	// Called for every pixel for every light affecting the material.
}

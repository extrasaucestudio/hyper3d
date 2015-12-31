#pragma require ShadingModel
#pragma require TextureLod
#pragma parameter seamless

uniform samplerCube u_texture;
uniform float u_textureLod;
uniform float u_textureSize;
uniform float u_roughness;
uniform float u_borderCoord;
uniform bvec3 u_axisIsMinor;
uniform float u_sampleRange;

varying vec3 v_dir;

// Lambert azimuthal equal-area projection
vec3 spheremap(vec2 v)
{
	vec4 nn = vec4(v, 1., -1.);
    float l = dot(nn.xyz, -nn.xyw);
    nn.z = l; nn.xy *= sqrt(l);
    return nn.xyz * 2. + vec3(0., 0., -1.); 
}

void makeAxis(vec3 ax, out vec3 ay, out vec3 az)
{
	vec3 up = abs(ax.z) > 0.5 ? vec3(1., 0., 0.) : vec3(0., 0., 1.);
	ay = cross(ax, up);
	az = cross(ay, ax);
}

void main()
{
	vec3 dir = v_dir;

	// texture cube seam elimination
	if (u_axisIsMinor.x) {
		if (abs(dir.x) >= u_borderCoord) {
			dir.x = sign(dir.x);
		}
	}
	if (u_axisIsMinor.y) {
		if (abs(dir.y) >= u_borderCoord) {
			dir.y = sign(dir.y);
		}
	}
	if (u_axisIsMinor.z) {
		if (abs(dir.z) >= u_borderCoord) {
			dir.z = sign(dir.z);
		}
	}

	vec3 dirU, dirV;
	makeAxis(dir, dirU, dirV);

	dir = normalize(dir);
	dirU = normalize(dirU);
	dirV = normalize(dirV);

	highp vec4 sum = vec4(0.);

	for (float x = -1.0; x <= 1.0; x += 0.05) {
		for (float y = -1.0; y <= 1.0; y += 0.05) {
			vec3 lrdir = spheremap(vec2(x, y) * u_sampleRange);
			vec3 rdir = lrdir.z * dir + lrdir.y * dirU + lrdir.x * dirV;
			float nhDot = lrdir.z;
			highp float chance = evaluateGGXSpecularDistribution(nhDot, u_roughness);
			vec4 value = myTextureCubeLod(u_texture, rdir, u_textureLod, u_textureSize);
			highp vec3 color = value.xyz * value.xyz; // linearize
			sum += vec4(color, 1.) * chance;
		}
	}

	highp vec3 result = sum.xyz / sum.w;
	gl_FragColor = vec4(sqrt(result), 1.);
}

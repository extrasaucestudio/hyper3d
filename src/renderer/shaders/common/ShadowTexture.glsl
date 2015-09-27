float shadowTexture2D(sampler2D tex, highp vec3 coord)
{
	highp float value = texture2D(tex, coord.xy).r;
	return step(coord.z, value);
}

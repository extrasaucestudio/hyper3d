// this shader is abstract; must be imported and main function must be provided

#pragma require HdrMosaic
#pragma require GBuffer
#pragma require ShadingModel
#pragma require DepthFetch

uniform sampler2D u_g0;
uniform sampler2D u_g1;
uniform sampler2D u_g2;
uniform sampler2D u_linearDepth;

uniform vec3 u_lightColor;

varying highp vec2 v_texCoord;
varying mediump vec2 v_viewDir;

uniform sampler2D u_dither;
varying highp vec2 v_ditherCoord;

highp vec3 computeViewPos()
{
	highp vec3 viewDir = vec3(v_viewDir, 1.);
	highp vec3 viewPos = viewDir * fetchDepth(u_linearDepth, v_texCoord);
	viewPos = -viewPos; // FIXME: ??
	return viewPos;
}

void emitLightPassOutput(vec3 lit)
{
	float lum = max(max(lit.x, lit.y), lit.z);

	// overflow protection
	const float lumLimit = HdrMosaicMaximumLevel * 0.7;
	if (lum > lumLimit) {
		lit *= lumLimit / lum;
	}

	// dither
	vec3 dither = texture2D(u_dither, v_ditherCoord).xyz;

	vec4 mosaicked = encodeHdrMosaicDithered(lit, dither);
	gl_FragColor = mosaicked;
}

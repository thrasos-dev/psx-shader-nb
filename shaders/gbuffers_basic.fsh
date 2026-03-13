#version 120
/* DRAWBUFFERS:0 */
#extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_texture_lod : enable

varying vec4 texcoord;
varying vec4 texcoordAffine;
varying vec4 lmcoord;
varying vec4 color;
varying vec4 normalMat;
varying vec3 viewPos;

#include "/lib/psx_util.glsl"

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform float viewWidth;
uniform float viewHeight;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

void main() {
	vec2 texelSize = vec2(1.0/viewWidth, 1.0/viewHeight);
	vec2 affine = AffineMapping(texcoordAffine, texcoord, texelSize, 2);

	// Dynamic hand light
	vec2 lm = lmcoord.st;
	#ifdef dynamic_hand_light
	int maxHeldLight = max(heldBlockLightValue, heldBlockLightValue2);
	if (maxHeldLight > 0) {
		float dist = length(viewPos);
		float atten = max(0.0, 1.0 - dist / float(maxHeldLight));
		atten *= atten;
		float dynamicLm = (float(maxHeldLight) * atten) / 16.0 + 1.0 / 32.0;
		lm.s = max(lm.s, dynamicLm);
	}
	#endif

	vec4 col = texture2D(texture, texcoord.xy) * color * (texture2D(lightmap, lm) * 0.8 + 0.2);
	
	gl_FragData[0] = col;
}

#version 120
/* DRAWBUFFERS:01 */
#extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_texture_lod : enable

#define gbuffers_solid
#include "/shaders.settings"

varying vec4 texcoord;
varying vec4 lmcoord;
varying vec4 color;
varying vec4 blockColor;
varying vec4 normalMat;
varying vec3 viewPos;

#include "/lib/psx_util.glsl"

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

void main() {
	vec3 normal = normalMat.xyz;

	// Dynamic hand light
	vec2 lm = lmcoord.st;
	#ifdef dynamic_hand_light
	int maxHeldLight = max(heldBlockLightValue, heldBlockLightValue2);
	if (maxHeldLight > 0) {
		float dynamicLm = float(maxHeldLight) / 16.0 + 1.0 / 32.0;
		lm.s = max(lm.s, dynamicLm);
	}
	#endif

	vec4 data0 = texture2D(texture, texcoord.xy) * color * (texture2D(lightmap, lm) * 0.8 + 0.2);
	
	gl_FragData[0] = data0;
}

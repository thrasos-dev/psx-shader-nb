#version 120
/* DRAWBUFFERS:01 */
#extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_texture_lod : enable

#define gbuffers_solid
#include "/shaders.settings"

varying vec4 texcoord;
varying vec4 texcoordAffine;
varying vec4 lmcoord;
varying vec4 color;
varying vec4 normalMat;
varying vec3 viewPos;

uniform float viewWidth;
uniform float viewHeight;
uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec4 entityColor;
uniform vec3 skyColor;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

#include "/lib/psx_util.glsl"


void main() {
	#ifdef affine_mapping
	#ifdef affine_clamp_enabled
	vec2 texelSize = vec2(1.0/viewWidth, 1.0/viewHeight);
	vec2 affine = AffineMapping(texcoordAffine, texcoord, texelSize, affine_clamp * 4.0);
	#else
	vec2 affine = texcoordAffine.xy / texcoordAffine.z;
	#endif
	#else 
	vec2 affine = texcoord.xy;
	#endif

	// Dynamic hand light
	vec2 lm = lmcoord.st;
	#ifdef dynamic_hand_light
	int maxHeldLight = max(heldBlockLightValue, heldBlockLightValue2);
	if (maxHeldLight > 0) {
		float dist = length(viewPos);
		float atten = max(0.0, 1.0 - dist / float(maxHeldLight));

		float dynamicLm = (float(maxHeldLight) * atten) / 16.0 + 1.0 / 32.0;
		lm.s = max(lm.s, dynamicLm);
	}
	#endif

	vec4 col = texture2D(texture, affine) * color * texture2D(lightmap, lm);
	col.rgb = mix(col.rgb, entityColor.rgb, entityColor.a);
	
	gl_FragData[0] = col;


}

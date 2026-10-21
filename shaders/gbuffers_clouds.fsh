#version 120
/* DRAWBUFFERS:6 */

#extension GL_EXT_gpu_shader4 : enable
#extension GL_ARB_shader_texture_lod : enable

// Not gbuffers_clouds: shaders.properties is preprocessed and would read blend.gbuffers_clouds as blend.1
#define clouds_pass
#include "/shaders.settings"

varying vec4 texcoord;
varying vec4 color;
varying vec3 normal;

uniform sampler2D texture;
uniform sampler2D lightmap;

void main() {
	#if cloud_style == 1 && defined IS_IRIS
	// composite draws the clouds
	discard;
	#endif

	vec4 tex = texture2D(texture, texcoord.xy);
	vec4 col = tex * color;

	#if cloud_style == 2
	// Vanilla shades faces 1.0 top, 0.7 bottom, 0.9 and 0.8 sides. Swap that for three flat tones.
	float vanillaShade = normal.y > 0.5 ? 1.0 : (normal.y < -0.5 ? 0.7 : (abs(normal.x) > 0.5 ? 0.9 : 0.8));
	float shade = normal.y > 0.5 ? 1.0 : (normal.y < -0.5 ? 0.6 : 0.8);
	col.rgb = col.rgb / vanillaShade * shade;
	// texture alpha is the density composite dithers with
	col.a = tex.a;
	#endif

	gl_FragData[0] = col;
}

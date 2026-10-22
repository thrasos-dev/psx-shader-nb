#version 120
/* DRAWBUFFERS:0 */

// Lightning has no lightmap coordinates. Without this program it falls back to gbuffers_entities,
// which multiplies by the lightmap, and bolts came out dim grey at night. Full alpha: vanilla's 0.3
// left the bolt faint once the PSX passes had downscaled it.

varying vec4 color;

void main() {
	gl_FragData[0] = vec4(color.rgb, 1.0);
}

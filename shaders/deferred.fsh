#version 120

// Saves vanilla's fog for composite: its colour, and where it starts and ends. The distances are
// only set while the world is drawn. By the time composite runs they have been cleared.

/*
const int colortex4Format = RGBA16F;
*/

uniform vec3 fogColor;
uniform float fogStart;
uniform float fogEnd;

void main() {
/* DRAWBUFFERS:24 */
	gl_FragData[0] = vec4(fogColor, 1.0);
	gl_FragData[1] = vec4(fogStart, fogEnd, 0.0, 1.0);
}

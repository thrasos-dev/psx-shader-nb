#version 120

// Skybox and rain shader code from Sildurs Vibrant Shaders

#define composite
#include "/shaders.settings"

varying vec2 texcoord;

varying vec3 lightColor;
varying vec3 sunVec;
varying vec3 upVec;
varying vec3 sky1;
varying vec3 sky2;

varying float tr;

varying vec2 lightPos;

varying vec3 sunlight;
varying vec3 nsunlight;

varying vec3 rawAvg;

varying float SdotU;
varying float sunVisibility;
varying float moonVisibility;

varying vec3 avgAmbient2;

uniform vec3 skyColor;
uniform mat4 gbufferProjectionInverse;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D depthtex2;
uniform sampler2D gaux2;
uniform sampler2D gaux3;
uniform sampler2D gaux4;
uniform vec2 texelSize;
uniform float viewWidth;
uniform float viewHeight;
uniform float near;
uniform float far;
uniform float rainStrength;
uniform int worldTime;
uniform int isEyeInWater;
uniform float playerMood;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjection;
uniform vec3 cameraPosition;

#if cloud_style == 1 && defined IS_IRIS
uniform sampler2D cloudMap;
uniform float cloudTime;
uniform float cloudHeight;
#endif

float bayer2(vec2 a) {
	a = floor(a);
	return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

// 0 to 15/16 in a 4x4 ordered pattern
float bayer4(vec2 a) {
	return bayer2(0.5 * a) * 0.25 + bayer2(a);
}

// 0, 0.5 or 1, like the PS1's half transparency, with dithered steps between
float cloudLevel(float density, float dither) {
	if (density > 0.45 + 0.15 * dither) return 1.0;
	#ifdef cloud_haze
	if (density > 0.08 + 0.1 * dither) return 0.5;
	#endif
	return 0.0;
}

// Vanilla's cloud colour: darker at night and in rain
vec3 cloudColor() {
	float day = clamp(SdotU * 2.0 + 0.5, 0.0, 1.0);
	vec3 c = mix(vec3(1.0), vec3(0.6), rainStrength * 0.95);
	return c * vec3(day * 0.9 + 0.1, day * 0.9 + 0.1, day * 0.85 + 0.15);
}

#if cloud_style == 1 && defined IS_IRIS
// Wrapped to the cloud map's 256 texels, so sin() keeps its precision as the clouds drift
float cloudHash(vec2 i) {
	i = mod(i, 256.0);
	return fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453);
}

float cloudNoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = p - i;
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(cloudHash(i), cloudHash(i + vec2(1.0, 0.0)), f.x),
	           mix(cloudHash(i + vec2(0.0, 1.0)), cloudHash(i + vec2(1.0, 1.0)), f.x), f.y);
}

// Cubic B-spline weights for the four texels around t
vec4 bspline(float t) {
	float t2 = t * t;
	float t3 = t2 * t;
	return vec4(1.0 - 3.0 * t + 3.0 * t2 - t3, 4.0 - 6.0 * t2 + 3.0 * t3, 1.0 + 3.0 * t + 3.0 * t2 - 3.0 * t3, t3) / 6.0;
}

float cloudTexel(vec2 c) {
	return texture2D(cloudMap, fract(c / 256.0)).a;
}

float cloudRow(vec2 i, float y, vec4 w) {
	return w.x * cloudTexel(i + vec2(-0.5, y)) + w.y * cloudTexel(i + vec2(0.5, y))
	     + w.z * cloudTexel(i + vec2(1.5, y)) + w.w * cloudTexel(i + vec2(2.5, y));
}

// Cloud map alpha at p (in texels), smoothed over 4x4 texels so shapes come out round
// instead of following the texel grid
float cloudDensity(vec2 p) {
	vec2 q = p - 0.5;
	vec2 i = floor(q);
	vec4 wx = bspline(q.x - i.x);
	vec4 wy = bspline(q.y - i.y);
	return wy.x * cloudRow(i, -0.5, wx) + wy.y * cloudRow(i, 0.5, wx)
	     + wy.z * cloudRow(i, 1.5, wx) + wy.w * cloudRow(i, 2.5, wx);
}

// The vanilla cloud map on one plane through the middle of the vanilla clouds, at the same
// offset and drift. Returns the colour, and its opacity (0, 0.5 or 1) in alpha.
vec4 flatClouds(vec3 viewPos, bool isSky, vec3 fogColor, float dither) {
	// NaN in dimensions without clouds
	if (!(cloudHeight > -10000.0 && cloudHeight < 10000.0)) return vec4(0.0);

	vec3 dir = normalize(mat3(gbufferModelViewInverse) * viewPos);
	float dy = cloudHeight + 2.33 - cameraPosition.y;
	if (dir.y * dy <= 0.0) return vec4(0.0);
	float t = dy / dir.y;
	if (!isSky && t > length(viewPos)) return vec4(0.0);

	// 12 blocks per texel, as vanilla
	vec2 p = (cameraPosition.xz + dir.xz * t + vec2(cloudTime, 0.0)) / 12.0 + vec2(0.0, 0.33);

	// Fade out where a texel shrinks to a few downscaled pixels, before it aliases
	float pixelAngle = 2.0 / (gbufferProjection[1][1] * viewHeight * resolution_scale);
	float texelAngle = 12.0 * abs(dir.y) / t;
	float fade = smoothstep(0.75, 3.0, texelAngle / pixelAngle);
	if (fade == 0.0) return vec4(0.0);

	// Wobble the lookup by up to 0.4 texels so long edges stop running along the grid
	vec2 warp = vec2(cloudNoise(p * 0.5), cloudNoise(p * 0.5 + vec2(37.0, 17.0))) - 0.5;
	float density = cloudDensity(p + warp * 0.8);

	float level = cloudLevel(density * fade, dither);
	if (level == 0.0) return vec4(0.0);

	// From below, the thick middle is a darker tone
	float shade = (dy > 0.0 && density > 0.85 + 0.1 * dither) ? 0.85 : 1.0;
	vec3 c = mix(cloudColor() * shade, fogColor, 0.3);
	return vec4(c, level);
}
#endif

vec3 getSkyColor(vec3 fposition) {
	const vec3 moonlightS = vec3(0.00575, 0.0105, 0.014);
	vec3 sVector = normalize(fposition);

	float invRain07 = 1.0-rainStrength*0.4;
	float cosT = dot(sVector,upVec);
	float mCosT = max(cosT,0.0);
	float absCosT = 1.0-max(cosT*0.82+0.26,0.2);
	float cosY = dot(sunVec,sVector);
	float Y = acos(cosY);

	const float a = -1.0;
	const float b = -0.22;
	const float c = 3.0;
	const float d = -6.5;
	const float e = 0.3;

	//luminance
	float L =  (1.0+a*exp(b/(mCosT)));
	float A = 1.0+e*cosY*cosY;

	//gradient
	vec3 grad1 = mix(sky1,sky2,absCosT*absCosT);
	float sunscat = max(cosY,0.0);
	vec3 grad3 = mix(grad1,nsunlight*(1.0-isEyeInWater),sunscat*sunscat*(1.0-mCosT)*(0.9-rainStrength*0.5*0.9)*(clamp(-(SdotU)*4.0+3.0,0.0,1.0)*0.65+0.35)+0.1);

	float Y2 = 3.14159265359-Y;
	float L2 = L * (8.0*exp(d*Y2)+A);

	const vec3 moonlight2 = pow(normalize(moonlightS),vec3(3.0))*length(moonlightS);
	const vec3 moonlightRain = normalize(vec3(0.25,0.3,0.5))*length(moonlightS) + 0.45;

	vec3 gradN = mix(moonlightS,moonlight2,1.-L2/2.0) + 0.35;
	gradN = mix(gradN,moonlightRain,rainStrength);
	return pow(L*(c*exp(d*Y)+A),invRain07)*sunVisibility *length(rawAvg) * (0.85+rainStrength*0.425)*grad3+ 0.2*pow(L2*1.2+1.2,invRain07)*moonVisibility*gradN;
}

void main() {
	float depth = texture2D(depthtex0, texcoord).r;
	float depth1 = texture2D(depthtex1, texcoord).r;
	
	bool sky = depth >= 1.0;
	bool skyNoClouds = depth1 >= 1.0;
	
	#ifdef fog_enabled
	float fogDepth = depth * fog_distance - (fog_distance-1);
	fogDepth = clamp(fogDepth, 0.0, 1.0);
	#else
	float fogDepth = (sky) ? 1.0 : 0.0;
	#endif
	vec3 col = texture2D(colortex0, texcoord).rgb;
	
	vec4 fragpos = gbufferProjectionInverse * (vec4(texcoord, depth1, 1.0) * 2.0 - 1.0);
	fragpos /= fragpos.w;
	vec3 normalfragpos = normalize(fragpos.xyz);
	
	vec3 skyCol = vec3(0.0);
	if (texcoord.x < 1.0 && texcoord.y < 1.0 && texcoord.x > 0.0 && texcoord.y > 0.0 && fogDepth > 0.0) {
		skyCol = getSkyColor(fragpos.xyz);
	}

	vec4 sunmoon = texture2D(gaux2, texcoord);
	vec4 clouds = texture2D(gaux3, texcoord);

	sunmoon *= (1.0-rainStrength);

	#if cloud_style != 0
	vec4 viewPos = gbufferProjectionInverse * (vec4(texcoord, depth, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;

	// Indexed like final.fsh samples, so each downscaled pixel gets one cell of the pattern
	vec2 dsRes = vec2(viewWidth, viewHeight) * resolution_scale;
	float dither = bayer4(floor(texcoord * (dsRes - 1.0) + 0.5)) + 0.03125;
	#endif

	vec3 fogColor = skyColor + skyCol;
	if(clouds.r > 0.0001) {
		#if cloud_style == 2
		// Fades out in steps before the edge of vanilla's cloud area (288 blocks on its short side)
		vec3 worldPos = mat3(gbufferModelViewInverse) * viewPos.xyz;
		float fade = smoothstep(96.0, 280.0, length(worldPos.xz));
		float level = cloudLevel(clouds.a * (1.0 - fade), dither);

		// What is behind the cloud. Clouds are not in depthtex1.
		#ifdef fog_enabled
		float fogDepth1 = clamp(depth1 * fog_distance - (fog_distance-1), 0.0, 1.0);
		#else
		float fogDepth1 = (skyNoClouds) ? 1.0 : 0.0;
		#endif
		vec3 behind = mix(col, fogColor, fogDepth1) + sunmoon.rgb * vec3(skyNoClouds?1.0:0.0);
		col = mix(behind, mix(clouds.rgb, fogColor, 0.2), level);
		#else
		clouds.rgb = mix(col*0.8, clouds.rgb, 0.75) + 0.1;
		float cloudsDepth = depth * 1000 - 999.2;
		cloudsDepth = clamp(cloudsDepth, 0.0, 1.0);
		col = mix(clouds.rgb, fogColor, cloudsDepth);
		col += sunmoon.rgb/2 * vec3(skyNoClouds?1.0:0.0);
		#endif
	} else {
		col = mix(col, fogColor, fogDepth);
		col += sunmoon.rgb * vec3(sky?1.0:0.0);

		#if cloud_style == 1 && defined IS_IRIS
		vec4 cloudLayer = flatClouds(viewPos.xyz, sky, fogColor, dither);
		col = mix(col, cloudLayer.rgb, cloudLayer.a);
		#endif
	}
	
	vec4 rain = texture2D(gaux4, texcoord);
	if (rain.r > 0.0001 && rainStrength > 0.01 && !(depth1 < texture2D(depthtex2, texcoord).x)){
		float rainRGB = 0.25;
		float rainA = rain.r;

		float torch_lightmap = 12.0 - min(rain.g/rain.r * 12.0,11.0);
		torch_lightmap = 0.5 / torch_lightmap / torch_lightmap - 0.010595;

		const vec3 moonlight = vec3(0.0025, 0.0045, 0.007);
		vec3 rainC = rainRGB*(pow(max(dot(normalfragpos, sunVec)*0.1+0.9,0.0),6.0)*(0.1+tr*0.9)*pow(sunlight,vec3(0.25))*sunVisibility+pow(max(dot(normalfragpos, -sunVec)*0.05+0.95,0.0),6.0)*48.0*moonlight*moonVisibility)*0.04 + 0.05*rainRGB*length(avgAmbient2);
		rainC += torch_lightmap*vec3(1.0,1.0,0.5);
		col = ((1.0-rainA*0.3)+rainC*1.5*rainA)*0.3;
	}
	
	if(isEyeInWater > 0) {
		col *= vec3(0.5, 0.6902, 1.0);
	}

	gl_FragData[0] = vec4(col, 1.0);
}

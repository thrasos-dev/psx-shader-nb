# PSX Shader NB

This shader pack is a fork of ckosmic's [Minecraft PSX Shader](https://github.com/ckosmic/minecraft-psx) that mimics the look and feel of PlayStation 1 graphics.

## Changes in this Fork

### No-Bounce Vertex Fix

Changed vertex transformation to eliminate the bouncing effect when moving.

Changed the vertex transformation from:

```glsl
vec4 position4 = mat4(gl_ModelViewMatrix) * vec4(gl_Vertex) + gl_ModelViewMatrix[3].xyzw;
```

to standard transformation:

```glsl
vec4 position4 = gl_ModelViewMatrix * vec4(gl_Vertex);
```

### Dynamic Hand Light

Added real dynamic lighting from held light sources (torches, lanterns, etc.). Light now updates continuously as you move, rather than only when breaking/placing blocks. Uses `heldBlockLightValue` / `heldBlockLightValue2` uniforms with linear distance falloff matching vanilla placed light behavior, applied to terrain, entities, water, hand, and basic geometry shaders. Supports both main hand and off hand light sources.

## Installation

Place this shader pack in your Minecraft `shaderpacks` folder.

This shader pack works with both [OptiFine](https://optifine.net/) and [Iris](https://irisshaders.net/).

## Credits

- Original shader by ckosmic
- Iris compatibility by Karen/あけみ (akemin_dayo)

## License

Licensed under the [MIT License](https://choosealicense.com/licenses/mit/).

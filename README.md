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

### Cloud Styles

Sky Settings > Cloud Style:

- **Vanilla**: Minecraft's clouds.
- **Flat**: one cloud layer at cloud height, drawn from the vanilla cloud texture, so shapes and drift match vanilla. Three levels of opacity (clear, half, solid) with dithered steps between, and a stepped fade toward the horizon. Needs Iris; on OptiFine it falls back to Vanilla. The Clouds video setting does not turn it off.
- **Blocky**: Minecraft's clouds with three flat tones (top, sides, bottom) and the same stepped opacity and fade.

Sky Settings > Cloud Haze, on by default, draws the thin parts of the cloud texture at half opacity around Flat and Blocky clouds. Off, those clouds are solid or clear.

With Sodium, Iris hides clouds under any shader pack, because Sodium draws them with its own shader. Set `mixin.features.render.world.clouds=false` in `config/sodium-mixins.properties` to get them back.

### Vanilla Fog

Post Processing Settings > Vanilla Fog, on by default. Where Minecraft's own fog is thick, it replaces the depth fog: the Nether, blindness, darkness, lava, powder snow, under water, and modded dimensions with thick fog. Elsewhere vanilla fog ends at the render distance, and the depth fog is used as before.

Iris only gives vanilla's fog distances to passes that run while the world is drawn, so `deferred` saves them, with the fog colour, for `composite` (`colortex4` and `colortex2`).

## Installation

Place this shader pack in your Minecraft `shaderpacks` folder.

This shader pack works with both [OptiFine](https://optifine.net/) and [Iris](https://irisshaders.net/).

## Credits

- Original shader by ckosmic
- Iris compatibility by Karen/あけみ (akemin_dayo)

## License

Licensed under the [MIT License](https://choosealicense.com/licenses/mit/).

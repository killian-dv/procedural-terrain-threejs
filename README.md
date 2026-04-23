# Procedural Terrain — Three.js Journey

Quick recap of the **Procedural Terrain** lesson from [Three.js Journey](https://threejsjourney.com/) by Bruno Simon.

## What this project covers

This project shows how to build an infinite-looking landscape from a subdivided plane by driving height entirely in the vertex shader with layered noise. Instead of baking heightmaps or replacing Three.js lighting, the setup uses `three-custom-shader-material` to inject custom GLSL into `MeshStandardMaterial`, so you keep familiar PBR controls while the surface is procedurally displaced and tinted by biome rules in the fragment shader.

- **Procedural elevation** from 2D simplex noise on the plane’s XZ coordinates, with **time-based domain warping** so the terrain evolves smoothly.
- A **small stack of noise octaves** (frequency doubling, amplitude halving) for richer detail than a single noise sample.
- **Non-linear shaping** of elevation (power curve) to exaggerate peaks and valleys in an art-directable way.
- **Normal reconstruction** from neighboring displaced positions so lighting matches the deformed mesh.
- **Height- and slope-driven coloring** (water, sand, grass, rock, snow) plus a **noise-thresholded snow line** for variation.
- A **custom depth material** that reuses the same vertex logic so shadow casting matches the displaced terrain.
- **Supporting scene pieces**: HDRI lighting, a translucent water plane, a CSG “frame” around the terrain, **lil-gui** for live tuning, and **OrbitControls** for inspection.

## What I built

- Set up `CustomShaderMaterial` with `THREE.MeshStandardMaterial` as the base for the terrain mesh.
- Created a high-segment `PlaneGeometry`, rotated it to lie in the XZ plane, and wired terrain vertex and fragment shaders plus shared uniforms.
- Loaded `spruit_sunrise.hdr` with `RGBELoader` for background, environment reflections, and a bit of background blurriness.
- Exposed terrain uniforms for shaping and motion:
  - `uTime` (animated warp and scrolling sampling for the snow noise input)
  - `uPositionFrequency`, `uStrength`
  - `uWarpFrequency`, `uWarpStrength`
  - `uColorWaterDeep`, `uColorWaterSurface`, `uColorSand`, `uColorGrass`, `uColorSnow`, `uColorRock`
- In the vertex shader:
  - warped XZ before the octave loop using `simplexNoise2d` and time
  - summed three octaves of noise, applied a signed power to elevation, then scaled by `uStrength`
  - displaced `csm_Position.y` and sampled two offset neighbors to rebuild `csm_Normal` with a cross product
  - passed `vPosition` (with optional XZ scroll for fragment noise) and `vUpDot` (normal vs. up) for shading
- In the fragment shader:
  - blended colors by height bands (water → sand → grass)
  - mixed rock where slopes are steep (`vUpDot`)
  - added procedural snow above a noisy height threshold
  - wrote the result to `csm_DiffuseColor`
- Added a matching `CustomShaderMaterial` based on `MeshDepthMaterial` with `RGBADepthPacking`, assigned as `terrain.customDepthMaterial`, so shadows align with the displaced geometry.
- Placed a simple **transmission** water plane slightly below the terrain and built a **white board** around the scene using `three-bvh-csg` (`Brush`, `Evaluator`, `SUBTRACTION`) so the terrain reads as a contained diorama.

## What I learned

### 1) How to extend standard Three.js materials safely

- `three-custom-shader-material` lets me inject custom GLSL while keeping the built-in lighting path of `MeshStandardMaterial`.
- This is often more practical than maintaining a full custom `ShaderMaterial` for every light feature.
- I still get sensible defaults (`metalness`, `roughness`, etc.) while the terrain’s shape and albedo come from shaders.

### 2) Why domain warping and octaves matter for terrain

- Warping the sample position with noise *before* the main elevation stack breaks up regular grid artifacts and feels more organic.
- Stacking octaves (higher frequency, lower amplitude each step) adds detail without one giant “blobby” frequency dominating.
- `uStrength` and the power curve on elevation are simple levers to push the look from gentle hills to dramatic cliffs without rewriting the shader.

### 3) Why normals must be recomputed after displacement

- The plane’s original normals are flat; once Y moves per vertex, they are wrong for lighting.
- Sampling the height function at two nearby XZ offsets and crossing the vectors gives a consistent up-facing normal field for moderate slopes.
- `vUpDot` (dot with world up) is a cheap way to detect steep faces for rock vs. grass in the fragment shader.

### 4) How to keep shadows consistent with displaced geometry

- The depth pass must use the **same** vertical displacement as the color pass.
- Reusing the terrain vertex shader on a `MeshDepthMaterial`-based `CustomShaderMaterial` keeps shadow maps glued to the visible surface.
- Without this, the terrain would cast shadows as if it were still a flat plane.

### 5) How fragment logic can read “biome” from varyings

- Height steps (`smoothstep`, `step`) give readable water / sand / grass bands.
- Slope from the recomputed normal sells rock on cliffs.
- A little extra noise on the snow threshold avoids a perfectly straight snow line and sells scale.

### 6) Practical real-time workflow improvements

- `lil-gui` makes frequency, strength, warp, and palette changes immediate and educational.
- An HDRI plus tone mapping and shadows makes material and height reads much clearer than a flat gray studio.
- Orbit controls + a simple water slab and CSG border turn the exercise into a small, presentable scene rather than a raw heightfield.

## Run the project

```bash
npm install
npm run dev
```

## Credits

Part of the **Three.js Journey** course by Bruno Simon.

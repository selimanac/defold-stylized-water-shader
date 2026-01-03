# Defold Stylized Water Shader

A stylized water shader implementation for the Defold game engine, featuring animated wave surfaces, foam effects, sparkles, and customizable rendering parameters. This is a direct port of [danielshervheim/unity-stylized-water](https://github.com/danielshervheim/unity-stylized-water) from Unity to Defold.

![Water Shader](/.github/day.jpg?raw=true)
![Water Shader](/.github/sunset.jpg?raw=true)


[![Water Shader](http://img.youtube.com/vi/TY02id9Rffs/0.jpg)](http://www.youtube.com/watch?v=TY02id9Rffs)

[![Water Shader](http://img.youtube.com/vi/4UVZur9TUp8/0.jpg)](http://www.youtube.com/watch?v=4UVZur9TUp8)

## Installation

You can use the Water Shader in your own project by adding this project as a [Defold library dependency](https://defold.com/manuals/libraries/#setting-up-library-dependencies).  
Open your `game.project` file, select  `Project` and add a  `Dependencies` field:


>https://github.com/selimanac/defold-stylized-water-shader/archive/refs/heads/main.zip  
>

[!WARNING]
> You have to set `shader.exclude_gles_sm100 = 1 in your game.project`

```ini
[shader]
exclude_gles_sm100 = 1
```

---

## Toss a Coin to Your Witcher
If you find my [Defold Extensions](https://github.com/selimanac) useful for your projects, please consider [supporting](https://github.com/sponsors/selimanac) it.  
I'd love to hear about your projects! Please share your released projects that use my native extensions. It would be very motivating for me.

---


## Quick Start

### Basic Setup

```lua
local water = require("water.water")

function init(self)
    -- Initialize water system
    water.init(
        msg.url("/camera"),           -- Camera instance URL
        msg.url("/camera#camera"),    -- Camera component URL
        msg.url("/sun"),              -- Sun instance URL
        msg.url("/water"),            -- Water instance URL
        0.1                           -- Time speed multiplier
    )
end

function update(self, dt)
    -- Update water animation
    water.update(dt)
end
```

### Simple Wave Configuration

```lua
-- Set gentle ocean waves
water.set_wave1(
    0.0,    -- direction (0° = east)
    0.3,    -- amplitude (gentle)
    25.0,   -- wavelength (ocean waves)
    1.5     -- speed (moderate)
)

-- Add a second wave layer
water.set_wave2(
    1.57,   -- direction (90° = north, π/2 radians)
    0.2,    -- amplitude (gentle)
    30.0,   -- wavelength (ocean waves)
    1.0     -- speed (slow/calm)
)
```

## API Reference

### Wave Functions

#### `water.set_wave1(direction, amplitude, wavelength, speed)`
Set first wave layer parameters.

**Parameters:**
- `direction` (number) - Wave direction in radians (0-2π)
  - 0 = east, π/2 = north, π = west, 3π/2 = south
- `amplitude` (number) - Wave height
  - 0.1-0.5 = gentle waves
  - 0.5-1.0 = medium waves
  - 1.0-2.0 = rough ocean
  - 2.0+ = storm!
- `wavelength` (number) - Distance between wave peaks
  - 10.0-20.0 = choppy water
  - 20.0-40.0 = ocean waves
  - 40.0+ = very long gentle swells
- `speed` (number) - Animation speed
  - 0.5-1.0 = slow/calm
  - 1.0-3.0 = moderate
  - 3.0-5.0 = fast
  - 5.0+ = very fast

**Example:**
```lua
water.set_wave1(0.0, 0.5, 20.0, 1.5)
```

---

#### `water.get_wave1()`
Get current wave1 parameters.

**Returns:** `direction, amplitude, wavelength, speed`

**Example:**
```lua
local dir, amp, wl, spd = water.get_wave1()
print(string.format("Wave1: dir=%.2f, amp=%.2f, wl=%.2f, spd=%.2f", 
    dir, amp, wl, spd))
```

---

#### `water.set_wave2(direction, amplitude, wavelength, speed)`
Set second wave layer parameters. Same parameters as `set_wave1`.

**Example:**
```lua
water.set_wave2(1.57, 0.3, 25.0, 1.2)
```

---

#### `water.get_wave2()`
Get current wave2 parameters.

**Returns:** `direction, amplitude, wavelength, speed`

---

### Wave Normal Functions

#### `water.set_wave_normal_params(scale, speed)`
Configure the animated normal map for surface ripple detail.

**Parameters:**
- `scale` (number) - Normal map tiling scale
  - 5.0 = large ripples
  - 10.0 = medium ripples
  - 20.0 = tiny ripples
- `speed` (number) - Animation speed
  - 0.5 = slow
  - 1.0 = normal
  - 2.0 = fast

**Example:**
```lua
water.set_wave_normal_params(12.0, 1.2)
```

---

#### `water.get_wave_normal_params()`
Get current wave normal parameters.

**Returns:** `scale, speed`

---

### Color Functions

#### `water.set_shallow_color(r, g, b)`
Set water color in shallow areas.

**Parameters:**
- `r, g, b` (number) - RGB color components (0.0-1.0)

**Note:** Alpha channel is not used (shader hardcodes to 1.0)

**Example:**
```lua
-- Tropical shallow water (bright cyan-green)
water.set_shallow_color(0.44, 0.95, 0.80)
```

---

#### `water.get_shallow_color()`
Get current shallow water color.

**Returns:** `r, g, b`

---

#### `water.set_deep_color(r, g, b)`
Set water color in deep areas.

**Parameters:**
- `r, g, b` (number) - RGB color components (0.0-1.0)

**Example:**
```lua
-- Deep ocean (dark blue)
water.set_deep_color(0.0, 0.1, 0.3)
```

---

#### `water.get_deep_color()`
Get current deep water color.

**Returns:** `r, g, b`

---

#### `water.set_far_color(r, g, b)`
Set water color at distance from camera.

**Parameters:**
- `r, g, b` (number) - RGB color components (0.0-1.0)

**Example:**
```lua
-- Distant water (lighter blue)
water.set_far_color(0.2, 0.4, 0.8)
```

---

#### `water.get_far_color()`
Get current far water color.

**Returns:** `r, g, b`

---

### Foam Functions

#### `water.set_foam_params(scale, speed, noise_scale, contribution)`
Configure foam appearance and animation.

**Parameters:**
- `scale` (number) - Foam texture tiling (lower = bigger foam patches)
- `speed` (number) - Animation speed
- `noise_scale` (number) - Normal map distortion amount (0.0-1.0)
  - 0.0 = no distortion (flat foam)
  - 0.5 = moderate distortion
  - 1.0 = heavy distortion
- `contribution` (number) - Overall foam visibility (0.0-1.0)
  - 0.0 = no foam
  - 0.5 = subtle foam
  - 1.0 = full foam

**Example:**
```lua
water.set_foam_params(8.0, 1.5, 0.7, 0.8)
```

---

#### `water.get_foam_params()`
Get current foam parameters.

**Returns:** `scale, speed, noise_scale, contribution`

**Example:**
```lua
local scale, speed, noise, contrib = water.get_foam_params()
print(string.format("Foam: scale=%.2f, speed=%.2f", scale, speed))
```

---

#### `water.set_edge_foam_params(depth_scale, noise_strength, edge_softness, alpha)`
Configure edge foam based on water depth.

**Parameters:**
- `depth_scale` (number) - How quickly foam fades with depth (lower = more foam)
- `noise_strength` (number) - Noise distortion strength (~0.2–0.5 recommended)
- `edge_softness` (number) - Edge blend softness (~0.02–0.15 recommended)
- `alpha` (number) - Overall foam opacity (0.0-1.0)

**Example:**
```lua
water.set_edge_foam_params(0.5, 0.3, 0.02, 0.8)  -- Moderate foam with soft edges
```

---

#### `water.get_edge_foam_params()`
Get current edge foam parameters.

**Returns:** `depth_scale, noise_strength, edge_softness, alpha`

---

#### `water.set_edge_foam_color(r, g, b)`
Set edge foam color.

**Parameters:**
- `r, g, b` (number) - RGB color components (0.0-1.0)

**Example:**
```lua
water.set_edge_foam_color(1.0, 1.0, 1.0)  -- White foam
```

---

#### `water.get_edge_foam_color()`
Get current edge foam color.

**Returns:** `r, g, b`

---

#### `water.set_edge_foam_type(type)`
Set edge foam rendering type.

**Parameters:**
- `type` (number) - 0 = no texture (solid color), 1 = textured

**Example:**
```lua
water.set_edge_foam_type(1)  -- Use textured foam
water.set_edge_foam_type(0)  -- Use solid color foam
```

---

#### `water.get_edge_foam_type()`
Get current edge foam type.

**Returns:** `type` (0 or 1)

---

### Rendering Functions

#### `water.set_density_params(distance_density, depth_density)`
Configure distance fade and depth color blending.

**Parameters:**
- `distance_density` (number) - Fade to far_color rate
  - 0.01 = very slow fade (see close color from far away)
  - 0.1 = normal fade
  - 0.5 = quick fade
- `depth_density` (number) - Water depth color blending intensity (higher = faster transition from shallow to deep)

**Example:**
```lua
water.set_density_params(0.1, 0.3)
```

---

#### `water.get_density_params()`
Get current density parameters.

**Returns:** `distance_density, depth_density`

---

### Sun Functions

#### `water.set_sun_params(exponent)`
Configure sun specular highlight sharpness.

**Parameters:**
- `exponent` (number) - Sun specular sharpness
  - 100 = big soft highlight
  - 1000 = medium sharp highlight
  - 10000 = tiny sharp highlight

**Example:**
```lua
water.set_sun_params(5000.0)  -- Sharp highlight
```

---

#### `water.get_sun_params()`
Get current sun parameters.

**Returns:** `exponent`

---

#### `water.set_sun_color(r, g, b)`
Set sun light color.

**Parameters:**
- `r, g, b` (number) - RGB color components (0.0-1.0)

**Example:**
```lua
water.set_sun_color(1.0, 0.95, 0.8)  -- Warm sunlight
```

---

#### `water.get_sun_color()`
Get current sun color.

**Returns:** `r, g, b`

---

#### `water.set_sun_direction(x, y, z)`
Set directional light direction (normalized).

**Parameters:**
- `x, y, z` (number) - Direction vector components

**Example:**
```lua
water.set_sun_direction(0.0, 0.5, 1.0)
```

---

#### `water.get_sun_direction()`
Get current sun direction.

**Returns:** `x, y, z`

---

### Sparkle Functions

#### `water.set_sparkle_params(scale, speed, exponent)`
Configure sparkle/glitter effects.

**Parameters:**
- `scale` (number) - Sparkle texture tiling
- `speed` (number) - Animation speed
- `exponent` (number) - Sharpness/intensity
  - 1000 = lots of soft sparkles
  - 10000 = medium sparkles
  - 100000 = very few, very sharp sparkles

**Example:**
```lua
water.set_sparkle_params(15.0, 0.5, 50000.0)
```

---

#### `water.get_sparkle_params()`
Get current sparkle parameters.

**Returns:** `scale, speed, exponent`

---

#### `water.set_sparkle_color(r, g, b)`
Set sparkle tint color.

**Parameters:**
- `r, g, b` (number) - RGB color components (0.0-1.0)

**Example:**
```lua
water.set_sparkle_color(1.0, 0.95, 0.8)  -- Slightly golden sparkles
```

---

#### `water.get_sparkle_color()`
Get current sparkle color.

**Returns:** `r, g, b`

---

### Refraction Functions

#### `water.set_refraction_params(strength, chromatic_aberration)`
Configure screen-space refraction effects.

**Parameters:**
- `strength` (number) - Overall refraction intensity (0.0-1.0)
  - 0.0 = no refraction
  - 0.5 = moderate refraction
  - 1.0 = strong refraction
- `chromatic_aberration` (number) - Color separation effect (0.0-1.0, optional)
  - 0.0 = no aberration
  - 0.5 = subtle color fringing
  - 1.0 = strong color separation

**Example:**
```lua
water.set_refraction_params(0.3, 0.2)  -- Moderate refraction with subtle aberration
```

---

#### `water.get_refraction_params()`
Get current refraction parameters.

**Returns:** `strength, chromatic_aberration`

---

### Reflection Functions

> **⚠️ NOTE**: Cubemap reflections are **enabled by default** but require a cubemap texture to be bound to work properly.

#### Disabling Reflections

To disable the cubemap reflections, you must:

1. **Comment the shader code** in `water/material/stylized_water.fp`:
   - Comment the `uniform samplerCube reflection_cubemap;` line
   - Comment the reflection code block in the `main()` function

2. **Comment the sampler** in `water/material/stylized_water.material`:
   - Find and comment the `samplers { name: "reflection_cubemap" ...` block



#### `water.set_reflection_params(strength, fresnel_power)`
Configure cubemap-based reflection effects (after enabling reflections as described above).

**Parameters:**
- `strength` (number) - Overall reflection intensity (0.0-1.0)
  - 0.0 = no reflection
  - 0.5 = moderate reflection
  - 1.0 = strong reflection
- `fresnel_power` (number) - Controls angle-dependent reflection (1.0-5.0, optional)
  - 1.0 = uniform reflection at all angles
  - 3.0 = natural fresnel - more reflection at grazing angles (default)
  - 5.0 = very strong grazing angle effect

**Example:**
```lua
water.set_reflection_params(0.6, 3.0)  -- 60% strength with natural fresnel
water.set_reflection_params(0.8, 5.0)  -- Strong reflections with pronounced fresnel
```

---

#### `water.get_reflection_params()`
Get current reflection parameters.

**Returns:** `strength, fresnel_power`

---

### LOD (Level of Detail) Functions

#### `water.set_lod_params(sparkle_distance, foam_distance)`
Configure Level-of-Detail distance thresholds for performance optimization.

**Parameters:**
- `sparkle_distance` (number) - Max distance for sparkle effect (0-500, default: 100)
  - Pixels beyond this distance skip sparkle calculation (saves 8 texture samples)
- `foam_distance` (number) - Max distance for full-quality foam (0-500, default: 150)
  - Pixels beyond this distance use simplified foam (saves 3 texture samples)

**Example:**
```lua
water.set_lod_params(100, 150)  -- Default balanced settings
water.set_lod_params(50, 80)    -- Close LOD for high quality
water.set_lod_params(200, 250)  -- Far LOD for better performance
```

---

#### `water.get_lod_params()`
Get current LOD parameters.

**Returns:** `sparkle_distance, foam_distance`

---

## Usage Examples

### Setting Water Colors

```lua
-- Tropical water
water.set_shallow_color(0.44, 0.95, 0.80)
water.set_deep_color(0.0, 0.3, 0.6)
water.set_far_color(0.1, 0.5, 0.9)

-- Dark ocean
water.set_shallow_color(0.2, 0.3, 0.3)
water.set_deep_color(0.0, 0.05, 0.1)
water.set_far_color(0.0, 0.1, 0.2)
```

### Adjusting Surface Details

```lua
-- Calm surface
water.set_wave_normal_params(15.0, 0.8)
water.set_foam_params(10.0, 0.5, 0.3, 0.4)

-- Rough surface
water.set_wave_normal_params(8.0, 2.0)
water.set_foam_params(5.0, 2.5, 0.8, 1.0)
```

### Water Presets

#### Calm Lake

```lua
function set_calm_lake()
    water.set_wave1(0.0, 0.1, 30.0, 0.5)
    water.set_wave2(0.5, 0.08, 35.0, 0.3)
    water.set_shallow_color(0.3, 0.6, 0.5)
    water.set_deep_color(0.1, 0.2, 0.3)
    water.set_foam_params(10.0, 0.5, 0.3, 0.4)
    water.set_sparkle_params(15.0, 0.3, 30000.0)
end
```

#### Storm Ocean

```lua
function set_storm_ocean()
    water.set_wave1(0.3, 2.5, 18.0, 4.0)
    water.set_wave2(1.2, 2.0, 22.0, 5.0)
    water.set_shallow_color(0.2, 0.3, 0.3)
    water.set_deep_color(0.0, 0.05, 0.1)
    water.set_foam_params(5.0, 3.0, 0.8, 1.0)
    water.set_sparkle_params(20.0, 1.5, 5000.0)
end
```

#### Tropical Paradise

```lua
function set_tropical_water()
    water.set_wave1(0.0, 0.4, 25.0, 1.2)
    water.set_wave2(0.8, 0.3, 28.0, 1.0)
    water.set_shallow_color(0.44, 0.95, 0.80)
    water.set_deep_color(0.0, 0.3, 0.6)
    water.set_far_color(0.1, 0.5, 0.9)
    water.set_foam_params(8.0, 1.2, 0.5, 0.7)
end
```

### Dynamic Effects

#### Gradually Increase Wave Intensity

```lua
function update_storm_effect(self, dt)
    local current_dir, current_amp, current_wl, current_spd = water.get_wave1()
    
    -- Increase amplitude and speed
    local new_amp = math.min(current_amp + dt * 0.1, 3.0)  -- Cap at 3.0
    local new_spd = math.min(current_spd + dt * 0.2, 6.0)  -- Cap at 6.0
    
    water.set_wave1(current_dir, new_amp, current_wl, new_spd)
end
```

#### Pulse Sparkle Intensity

```lua
function update_sparkle_pulse(self, time)
    local base_exp = 10000.0
    local pulse = math.sin(time * 2.0) * 0.5 + 0.5  -- Oscillate 0-1
    local exponent = base_exp + pulse * 50000.0
    
    local scale, speed = water.get_sparkle_params()
    water.set_sparkle_params(scale, speed, exponent)
end
```

#### Time-of-Day Color Transition

```lua
function update_water_time_of_day(self, time_normalized)
    -- time_normalized: 0.0 = midnight, 0.25 = dawn, 0.5 = noon, 0.75 = dusk
    
    if time_normalized < 0.25 then
        -- Night to dawn
        local t = time_normalized / 0.25
        water.set_deep_color(
            0.0 + t * 0.05,
            0.05 + t * 0.15,
            0.1 + t * 0.3
        )
    elseif time_normalized < 0.75 then
        -- Day colors
        water.set_deep_color(0.0, 0.2, 0.4)
        water.set_far_color(0.1, 0.4, 0.8)
    else
        -- Dusk to night
        local t = (time_normalized - 0.75) / 0.25
        water.set_deep_color(
            0.05 - t * 0.05,
            0.2 - t * 0.15,
            0.4 - t * 0.3
        )
    end
end
```

### Enabling Refraction and Reflection

```lua
-- Enable refraction with moderate distortion
water.set_refraction_params(0.3, 0.0)  -- Recommended: 0.1-0.3 strength

-- Or with chromatic aberration for a more stylized look
water.set_refraction_params(0.4, 0.2)

-- Enable reflections (after binding cubemap in collection)
water.set_reflection_params(0.6, 3.0)  -- 60% strength, natural fresnel
water.set_reflection_params(0.8, 5.0)  -- Strong reflections with pronounced effect

-- Disable effects by setting strength to 0
water.set_refraction_params(0.0, 0.0)
water.set_reflection_params(0.0, 3.0)
```

## Important Notes

- **Color Values**: All color values are in the range 0.0-1.0 (not 0-255)
- **Alpha Channel**: Alpha is not used - the shader hardcodes output alpha to 1.0
- **Direction Values**: Direction values are in radians (0-2π), where 0 = east, π/2 = north
- **Refraction**: Scene is rendered to a render target. Keep the strength between 0.1 and 0.3 for best results. Higher values may cause artifacts.
- **Reflection**: Fresnel power controls angle-dependent effect; 1.0 = uniform, 5.0 = strong.

## Project Structure

```
/
├── water/                    # Water module
│   ├── water.lua            # Main water API module
│   ├── material/            # Water material and shaders
│   └── render/              # Render script components
├── assets/                  # Textures and models
│   ├── Textures/           # Water textures (normals, foam, sparkles)
│   └── Models/             # 3D models
├── main/                    # Demo scene
└── WATER_API_EXAMPLES.md   # Detailed usage examples
```

## Credits

- Original Unity implementation: [danielshervheim/unity-stylized-water](https://github.com/danielshervheim/unity-stylized-water)


---

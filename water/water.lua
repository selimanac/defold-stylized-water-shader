-- =======================================
-- MODULE
-- =======================================
local water                  = {}

-- =======================================
-- VARS
-- =======================================
local water_camera_instance  = msg.url()
local water_camera_component = msg.url()
local sun_instance           = msg.url()
local sun_position           = vmath.vector3()
local water_instance         = msg.url()
local time                   = 0
local time_speed             = 0

--[[
	WATER SHADER CONSTANTS DOCUMENTATION
	
	wave1 (vec4) - First wave layer
		x: Direction (radians, 0-2π) - Wave propagation direction (0° = east, π/2 = north)
		y: Amplitude - Wave height
			0.1 - 0.5 = gentle waves
			0.5 - 1.0 = medium waves
			1.0 - 2.0 = rough ocean
			2.0+ = storm!
		z: Wavelength - Distance between wave peaks
			10.0 - 20.0 = choppy water
			20.0 - 40.0 = ocean waves
			40.0+ = very long gentle swells
		w: Speed - Animation speed
			0.5 - 1.0 = slow/calm
			1.0 - 3.0 = moderate
			3.0 - 5.0 = fast
			5.0+ = very fast
	
	wave2 (vec4) - Second wave layer (same parameters as wave1)
		x: Direction (radians)
		y: Amplitude
		z: Wavelength
		w: Speed
	
	wave_normal_params (vec4) - Animated normal map for surface detail
		x: Scale - How tiled the normal map is
			5.0 = large ripples
			10.0 = medium ripples
			20.0 = tiny ripples
		y: Speed - Animation speed (0.5 = slow, 1.0 = normal, 2.0 = fast)
	
	shallow_color (vec4) - Water color in shallow areas (RGB, 0.0-1.0)
	deep_color (vec4) - Water color in deep areas (RGB, 0.0-1.0)
	far_color (vec4) - Water color at distance from camera (RGB, 0.0-1.0)
	Note: Alpha channel is not used in the shader (hardcoded to 1.0)
	
	foam_params (vec4) - Foam texture layer
		x: Scale - Foam texture tiling (lower = bigger foam patches)
		y: Speed - Animation speed
		z: Noise Scale - Normal map distortion amount (0.0-1.0)
			0.0 = no distortion (flat foam)
			0.5 = moderate distortion
			1.0 = heavy distortion
		w: Contribution - Overall foam visibility (0.0-1.0)
			0.0 = no foam
			0.5 = subtle foam
			1.0 = full foam
	
	density_params (vec4) - Distance and depth rendering parameters
		x: Distance Density - Fade to far_color based on camera distance
			0.01 = very slow fade (see close color from far away)
			0.1 = normal fade
			0.5 = quick fade
		y: Depth Density - Water depth color blending intensity
			Higher values = faster transition from shallow to deep color
	
	sun_params (vec4) - Sun rendering parameters
		x: Exponent - Sun specular sharpness
			100 = big soft highlight
			1000 = medium sharp highlight
			10000 = tiny sharp highlight
	
	sun_color (vec4) - Sun light color (RGB, 0.0-1.0)
	sun_direction (vec4) - Directional light direction (XYZ, normalized)
	
	sparkle_params (vec4) - Sparkle/glitter effect
		x: Scale - Sparkle texture tiling
		y: Speed - Animation speed
		z: Exponent - Sharpness/intensity (higher = sharper, fewer sparkles)
			1000 = lots of soft sparkles
			10000 = medium sparkles
			100000 = very few, very sharp sparkles
		w: Enabled - 0.0 = disabled, 1.0 = enabled
	
	sparkle_color (vec4) - Sparkle tint color (RGB, 0.0-1.0)
	
	edge_foam_params (vec4) - Edge foam parameters
		x: Depth Scale - How quickly foam fades with depth (lower = more foam)
		y: Noise Strength - Noise distortion strength (~0.2–0.5 recommended)
		z: Edge Softness - Edge blend softness (~0.02–0.15 recommended)
		w: Alpha - Overall foam opacity (0.0-1.0)
	
	edge_foam_color (vec4) - Edge foam color (RGB, 0.0-1.0)
	
	edge_foam_type (vec4) - Edge foam rendering type
		x: Type - 0 = no texture (solid color), 1 = textured

	refraction_params (vec4) - Refraction effect parameters
		x: Strength - Overall refraction intensity (0.0-1.0)
			0.0 = no refraction
			0.5 = moderate refraction
			1.0 = strong refraction
		y: Chromatic Aberration - Color separation effect (0.0-1.0)
			0.0 = no aberration
			0.5 = subtle color fringing
			1.0 = strong color separation

	reflection_params (vec4) - Reflection effect parameters
		x: Strength - Overall reflection intensity (0.0-1.0)
			0.0 = no reflection
			0.5 = moderate reflection
			1.0 = strong reflection
		y: Fresnel Power - Controls angle-dependent reflection (1.0-5.0)
			1.0 = reflection at all angles
			3.0 = more reflection at grazing angles
			5.0 = very strong grazing angle effect

	lod_params (vec4) - Level-of-detail distance thresholds
		x: Sparkle Distance - Max distance for sparkle effect (0-500)
			Pixels beyond this distance skip sparkle (saves 8 texture samples)
		y: Foam Distance - Max distance for full-quality foam (0-500)
			Pixels beyond this distance use simplified foam (saves 3 texture samples)
]]

local constants = {
	-- colors
	shallow_color      = vmath.vector4(0.44, 0.95, 0.36, 1.0),
	deep_color         = vmath.vector4(3 / 255, 9 / 255, 49 / 255, 1.0),
	far_color          = vmath.vector4(1 / 255, 35 / 255, 119 / 255, 1.0),
	sun_color          = vmath.vector4(255.0 / 255.0, 228.0 / 255.0, 132.0 / 255.0, 1.0),
	sparkle_color      = vmath.vector4(1.0, 1.0, 1.0, 1.0),
	edge_foam_color    = vmath.vector4(1.0, 1.0, 1.0, 1.0),

	-- waves
	wave1              = vmath.vector4(1.5, 0.3, 20.0, 3.3),
	wave2              = vmath.vector4(1.6, 0.6, 15.0, 1.8),
	wave_normal_params = vmath.vector4(15.0, 1.0, 0.0, 0.0),

	-- sun
	sun_direction      = vmath.vector4(0.0, 0.5, 1.0, 1.0),
	sun_params         = vmath.vector4(1000.0, 0.0, 0.0, 1.0),

	-- foam
	foam_params        = vmath.vector4(10.0, 1.0, 0.5, 1.0),
	edge_foam_type     = vmath.vector4(1.0, 1.0, 1.0, 1.0), -- 0 no texture, 1 texture
	edge_foam_params   = vmath.vector4(0.5, 0.3, 0.02, 0.8), -- y noise_strength  ~0.2–0.5 , edge_softness ~0.02–0.15


	--sparkles
	sparkle_params    = vmath.vector4(40.0, 0.3, 10000.0, 1.0),

	-- density
	density_params    = vmath.vector4(0.02, 0.4, 0.0, 1.0),

	-- camera
	camera_pos        = vmath.vector4(0.0, 0.0, 0.0, 0.0),
	camera_proj       = vmath.vector4(0.1, 1000.0, 0.0, 0.0),

	-- time
	time              = vmath.vector4(0.0, 0.0, 0.0, 0.0),
	time_v            = vmath.vector4(0.0, 0.0, 0.0, 0.0),

	--  light position for models
	light             = vmath.vector4(1.0, 1.0, 0.0, 0.0),

	-- refraction and reflection
	refraction_params = vmath.vector4(0.1, 0.0, 0.0, 0.0),
	reflection_params = vmath.vector4(0.5, 1.0, 0.0, 0.0), -- Enabled by default (strength=0) since cubemap not supported yet

	-- LOD (Level of Detail)
	lod_params        = vmath.vector4(100.0, 150.0, 0.0, 0.0), -- sparkle_distance, foam_distance
}


local function internal_update_buffer(self)
	self.water_constant_buffer.wave1 = constants.wave1
	self.water_constant_buffer.wave2 = constants.wave2
	self.water_constant_buffer.time = constants.time
	self.water_constant_buffer.time_v = constants.time
	self.water_constant_buffer.wave_normal_params = constants.wave_normal_params
	self.water_constant_buffer.shallow_color = constants.shallow_color
	self.water_constant_buffer.deep_color = constants.deep_color
	self.water_constant_buffer.far_color = constants.far_color
	self.water_constant_buffer.foam_params = constants.foam_params
	self.water_constant_buffer.density_params = constants.density_params
	self.water_constant_buffer.sun_params = constants.sun_params
	self.water_constant_buffer.sun_color = constants.sun_color
	self.water_constant_buffer.sun_direction = constants.sun_direction
	self.water_constant_buffer.sparkle_params = constants.sparkle_params
	self.water_constant_buffer.sparkle_color = constants.sparkle_color
	self.water_constant_buffer.edge_foam_type = constants.edge_foam_type
	self.water_constant_buffer.edge_foam_params = constants.edge_foam_params
	self.water_constant_buffer.edge_foam_color = constants.edge_foam_color
	self.water_constant_buffer.camera_pos = constants.camera_pos
	self.water_constant_buffer.projection_params = constants.camera_proj
	self.water_constant_buffer.refraction_params = constants.refraction_params
	self.water_constant_buffer.reflection_params = constants.reflection_params
	self.water_constant_buffer.lod_params = constants.lod_params

	self.light_constant_buffer.light = constants.light
end

local function internal_update_camera()
	local camera_pos        = go.get_position(water_camera_instance)
	constants.camera_pos.x  = camera_pos.x
	constants.camera_pos.y  = camera_pos.y
	constants.camera_pos.z  = camera_pos.z

	constants.camera_proj.x = camera.get_near_z(water_camera_component)
	constants
	.camera_proj.y          = camera.get_far_z(water_camera_component)
end

local function internal_update_sun()
	sun_position = go.get_position(sun_instance)
	constants.light.x = sun_position.x
	constants.light.y = sun_position.y
	constants.light.z = sun_position.z

	local water_pos = go.get_position(water_instance)
	local sun_dir = sun_position - water_pos
	sun_dir = vmath.normalize(sun_dir)

	constants.sun_direction.x = sun_dir.x
	constants.sun_direction.y = sun_dir.y
	constants.sun_direction.z = sun_dir.z
end

function water.init(camera_url, camera_component_url, sun_url, water_url, _time_speed)
	time_speed             = _time_speed
	water_camera_instance  = camera_url
	water_camera_component = camera_component_url
	sun_instance           = sun_url
	water_instance         = water_url
	-- Note: Cubemap path parameter removed - reflections currently not supported
	-- TODO: Implement proper cubemap reflection support

	internal_update_camera()
	internal_update_sun()
end

function water.render_init(self)
	self.predicates["water"] = render.predicate({ "water" })

	-- RENDER TARGET BUFFER PARAMETERS
	local color_params = {
		format = graphics.TEXTURE_FORMAT_RGBA,
		width = self.state.width,
		height = self.state.height,
		min_filter = graphics.TEXTURE_FILTER_LINEAR,
		mag_filter = graphics.TEXTURE_FILTER_LINEAR,
		u_wrap = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE,
		v_wrap = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE
	}

	local depth_params = {
		format     = graphics.TEXTURE_FORMAT_DEPTH,
		width      = self.state.width,
		height     = self.state.height,
		min_filter = graphics.TEXTURE_FILTER_NEAREST,
		mag_filter = graphics.TEXTURE_FILTER_NEAREST,
		u_wrap     = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE,
		v_wrap     = graphics.TEXTURE_WRAP_CLAMP_TO_EDGE,
		flags      = render.TEXTURE_BIT
	}

	self.depth_rt = render.render_target(
		"scene",
		{
			[graphics.BUFFER_TYPE_COLOR0_BIT] = color_params,
			[graphics.BUFFER_TYPE_DEPTH_BIT] = depth_params
		})

	self.water_constant_buffer = render.constant_buffer()
	self.light_constant_buffer = render.constant_buffer()

	internal_update_buffer(self)
end

function water.render_update(self, state, predicates, draw_options_world)
	internal_update_buffer(self)

	render.set_render_target(self.depth_rt)
	render.set_render_target_size(self.depth_rt, state.window_width, state.window_height)
	render.clear(state.clear_buffers)
	render.enable_state(graphics.STATE_CULL_FACE)
	render.draw(predicates.model, draw_options_world)
	render.disable_state(graphics.STATE_CULL_FACE)

	render.set_render_target(render.RENDER_TARGET_DEFAULT)
	-- render `model` predicate for default 3D material
	--
	render.enable_state(graphics.STATE_CULL_FACE)
	render.draw(predicates.model, { constants = self.light_constant_buffer })

	-- Enable textures for water shader
	render.enable_texture("depth_texture", self.depth_rt, graphics.BUFFER_TYPE_DEPTH_BIT)
	render.enable_texture("refraction_texture", self.depth_rt, graphics.BUFFER_TYPE_COLOR0_BIT)

	render.draw(predicates.water, { constants = self.water_constant_buffer })

	-- Disable textures
	render.disable_texture("depth_texture")
	render.disable_texture("refraction_texture")

	render.set_depth_mask(false)
	render.disable_state(graphics.STATE_CULL_FACE)
end

function water.update_sun()
	internal_update_sun()
end

function water.update_camera()
	internal_update_camera()
end

function water.update(dt)
	time = time + dt * time_speed
	constants.time.x = time
	constants.time_v.x = time
end

-- ============================================================================
-- WAVE CONSTANTS SETTERS AND GETTERS
-- ============================================================================

--- Set wave1 parameters
-- @param direction Wave direction in radians (0-2π)
-- @param amplitude Wave height (0.1-0.5 gentle, 0.5-1.0 medium, 1.0-2.0 rough, 2.0+ storm)
-- @param wavelength Distance between wave peaks (10-20 choppy, 20-40 ocean, 40+ gentle swells)
-- @param speed Animation speed (0.5-1.0 slow, 1.0-3.0 moderate, 3.0-5.0 fast, 5.0+ very fast)
function water.set_wave1(direction, amplitude, wavelength, speed)
	constants.wave1.x = direction
	constants.wave1.y = amplitude
	constants.wave1.z = wavelength
	constants.wave1.w = speed
end

--- Get wave1 parameters
-- @return direction, amplitude, wavelength, speed
function water.get_wave1()
	return constants.wave1.x, constants.wave1.y, constants.wave1.z, constants.wave1.w
end

--- Set wave2 parameters
-- @param direction Wave direction in radians (0-2π)
-- @param amplitude Wave height (0.1-0.5 gentle, 0.5-1.0 medium, 1.0-2.0 rough, 2.0+ storm)
-- @param wavelength Distance between wave peaks (10-20 choppy, 20-40 ocean, 40+ gentle swells)
-- @param speed Animation speed (0.5-1.0 slow, 1.0-3.0 moderate, 3.0-5.0 fast, 5.0+ very fast)
function water.set_wave2(direction, amplitude, wavelength, speed)
	constants.wave2.x = direction
	constants.wave2.y = amplitude
	constants.wave2.z = wavelength
	constants.wave2.w = speed
end

--- Get wave2 parameters
-- @return direction, amplitude, wavelength, speed
function water.get_wave2()
	return constants.wave2.x, constants.wave2.y, constants.wave2.z, constants.wave2.w
end

-- ============================================================================
-- WAVE NORMAL PARAMS SETTERS AND GETTERS
-- ============================================================================

--- Set wave normal map parameters
-- @param scale Normal map tiling (5.0 large ripples, 10.0 medium, 20.0 tiny)
-- @param speed Animation speed (0.5 slow, 1.0 normal, 2.0 fast)
function water.set_wave_normal_params(scale, speed)
	constants.wave_normal_params.x = scale
	constants.wave_normal_params.y = speed
end

--- Get wave normal map parameters
-- @return scale, speed
function water.get_wave_normal_params()
	return constants.wave_normal_params.x, constants.wave_normal_params.y
end

-- ============================================================================
-- COLOR CONSTANTS SETTERS AND GETTERS
-- ============================================================================

--- Set shallow water color
-- @param r Red component (0.0-1.0)
-- @param g Green component (0.0-1.0)
-- @param b Blue component (0.0-1.0)
function water.set_shallow_color(r, g, b)
	constants.shallow_color.x = r
	constants.shallow_color.y = g
	constants.shallow_color.z = b
end

--- Get shallow water color
-- @return r, g, b
function water.get_shallow_color()
	return constants.shallow_color.x, constants.shallow_color.y,
		constants.shallow_color.z
end

--- Set deep water color
-- @param r Red component (0.0-1.0)
-- @param g Green component (0.0-1.0)
-- @param b Blue component (0.0-1.0)
function water.set_deep_color(r, g, b)
	constants.deep_color.x = r
	constants.deep_color.y = g
	constants.deep_color.z = b
end

--- Get deep water color
-- @return r, g, b
function water.get_deep_color()
	return constants.deep_color.x, constants.deep_color.y,
		constants.deep_color.z
end

--- Set far water color (color at distance from camera)
-- @param r Red component (0.0-1.0)
-- @param g Green component (0.0-1.0)
-- @param b Blue component (0.0-1.0)
function water.set_far_color(r, g, b)
	constants.far_color.x = r
	constants.far_color.y = g
	constants.far_color.z = b
end

--- Get far water color
-- @return r, g, b
function water.get_far_color()
	return constants.far_color.x, constants.far_color.y,
		constants.far_color.z
end

-- ============================================================================
-- FOAM PARAMS SETTERS AND GETTERS
-- ============================================================================

--- Set foam parameters
-- @param scale Foam texture tiling (lower = bigger foam patches)
-- @param speed Animation speed
-- @param noise_scale Normal map distortion (0.0 no distortion, 0.5 moderate, 1.0 heavy)
-- @param contribution Overall foam visibility (0.0 no foam, 0.5 subtle, 1.0 full)
function water.set_foam_params(scale, speed, noise_scale, contribution)
	constants.foam_params.x = scale
	constants.foam_params.y = speed
	constants.foam_params.z = noise_scale
	constants.foam_params.w = contribution
end

--- Get foam parameters
-- @return scale, speed, noise_scale, contribution
function water.get_foam_params()
	return constants.foam_params.x, constants.foam_params.y,
		constants.foam_params.z, constants.foam_params.w
end

-- ============================================================================
-- DENSITY PARAMS SETTERS AND GETTERS
-- ============================================================================

--- Set density and rendering parameters
-- @param distance_density Fade to far_color rate (0.01 very slow, 0.1 normal, 0.5 quick)
-- @param depth_density Water depth color blending intensity
function water.set_density_params(distance_density, depth_density)
	constants.density_params.x = distance_density
	constants.density_params.y = depth_density
end

--- Get density and rendering parameters
-- @return distance_density, depth_density
function water.get_density_params()
	return constants.density_params.x, constants.density_params.y
end

-- ============================================================================
-- SUN PARAMS SETTERS AND GETTERS
-- ============================================================================

--- Set sun rendering parameters
-- @param exponent Sun specular sharpness (100 soft, 1000 medium, 10000 sharp)
function water.set_sun_params(exponent)
	constants.sun_params.x = exponent
end

--- Get sun rendering parameters
-- @return exponent
function water.get_sun_params()
	return constants.sun_params.x
end

--- Set sun light color
-- @param r Red component (0.0-1.0)
-- @param g Green component (0.0-1.0)
-- @param b Blue component (0.0-1.0)
function water.set_sun_color(r, g, b)
	constants.sun_color.x = r
	constants.sun_color.y = g
	constants.sun_color.z = b
end

--- Get sun light color
-- @return r, g, b
function water.get_sun_color()
	return constants.sun_color.x, constants.sun_color.y,
		constants.sun_color.z
end

--- Set sun direction (directional light direction)
-- @param x X component (normalized)
-- @param y Y component (normalized)
-- @param z Z component (normalized)
function water.set_sun_direction(x, y, z)
	constants.sun_direction.x = x
	constants.sun_direction.y = y
	constants.sun_direction.z = z
end

--- Get sun direction
-- @return x, y, z
function water.get_sun_direction()
	return constants.sun_direction.x, constants.sun_direction.y,
		constants.sun_direction.z
end

-- ============================================================================
-- SPARKLE PARAMS SETTERS AND GETTERS
-- ============================================================================

--- Set sparkle/glitter effect parameters
-- @param scale Sparkle texture tiling
-- @param speed Animation speed
-- @param exponent Sharpness/intensity (1000 soft, 10000 medium, 100000 sharp/few)
-- @param enabled Optional: 0.0 = disabled, 1.0 = enabled (default: keep current value)
function water.set_sparkle_params(scale, speed, exponent, enabled)
	constants.sparkle_params.x = scale
	constants.sparkle_params.y = speed
	constants.sparkle_params.z = exponent
	if enabled ~= nil then
		constants.sparkle_params.w = enabled
	end
end

--- Get sparkle parameters
-- @return scale, speed, exponent, enabled
function water.get_sparkle_params()
	return constants.sparkle_params.x, constants.sparkle_params.y,
		constants.sparkle_params.z, constants.sparkle_params.w
end

--- Enable sparkle effect
function water.enable_sparkle()
	constants.sparkle_params.w = 1.0
end

--- Disable sparkle effect (saves 8 texture samples per fragment)
function water.disable_sparkle()
	constants.sparkle_params.w = 0.0
end

--- Check if sparkle is enabled
-- @return true if enabled, false if disabled
function water.is_sparkle_enabled()
	return constants.sparkle_params.w > 0.5
end

--- Set sparkle tint color
-- @param r Red component (0.0-1.0)
-- @param g Green component (0.0-1.0)
-- @param b Blue component (0.0-1.0)
function water.set_sparkle_color(r, g, b)
	constants.sparkle_color.x = r
	constants.sparkle_color.y = g
	constants.sparkle_color.z = b
end

--- Get sparkle tint color
-- @return r, g, b
function water.get_sparkle_color()
	return constants.sparkle_color.x, constants.sparkle_color.y,
		constants.sparkle_color.z
end

-- ============================================================================
-- EDGE FOAM PARAMS SETTERS AND GETTERS
-- ============================================================================

--- Set edge foam parameters
-- @param depth_scale Depth scale for edge foam (how quickly foam fades with depth)
-- @param noise_strength
-- @param edge_softness
-- @param alpha
function water.set_edge_foam_params(depth_scale, noise_strength, edge_softness, alpha)
	constants.edge_foam_params.x = depth_scale
	constants.edge_foam_params.y = noise_strength
	constants.edge_foam_params.z = edge_softness
	constants.edge_foam_params.w = alpha
end

--- Get edge foam parameters
-- @return depth_scale, noise_strength, edge_softness, alpha
function water.get_edge_foam_params()
	return constants.edge_foam_params.x, constants.edge_foam_params.y, constants.edge_foam_params.z, constants.edge_foam_params.w
end

--- Set edge foam type
-- @param type 0 no texture 1 for textured
function water.set_edge_foam_type(type)
	print("SET", type)
	constants.edge_foam_type.x = type
end

--- Get edge foam parameters
-- @return type
function water.get_edge_foam_type()
	return constants.edge_foam_type.x
end

--- Set edge foam color
-- @param r Red component (0.0-1.0)
-- @param g Green component (0.0-1.0)
-- @param b Blue component (0.0-1.0)
function water.set_edge_foam_color(r, g, b)
	constants.edge_foam_color.x = r
	constants.edge_foam_color.y = g
	constants.edge_foam_color.z = b
end

--- Get edge foam color
-- @return r, g, b
function water.get_edge_foam_color()
	return constants.edge_foam_color.x, constants.edge_foam_color.y,
		constants.edge_foam_color.z
end

-- ============================================================================
-- REFRACTION PARAMS SETTERS AND GETTERS
-- ============================================================================

--- Set refraction parameters
-- @param strength Overall refraction intensity (0.0-1.0, 0=off, 0.5=moderate, 1.0=strong)
-- @param chromatic_aberration Color separation effect (0.0-1.0, 0=off, 0.5=subtle, 1.0=strong)
function water.set_refraction_params(strength, chromatic_aberration)
	constants.refraction_params.x = strength
	constants.refraction_params.y = chromatic_aberration or 0.0
end

--- Get refraction parameters
-- @return strength, chromatic_aberration
function water.get_refraction_params()
	return constants.refraction_params.x, constants.refraction_params.y
end

-- ============================================================================
-- REFLECTION PARAMS SETTERS AND GETTERS
-- ============================================================================

--- Set reflection parameters
-- @param strength Overall reflection intensity (0.0-1.0, 0=off, 0.5=moderate, 1.0=strong)
-- @param fresnel_power Controls angle-dependent reflection (1.0-5.0, 1.0=all angles, 3.0=grazing, 5.0=very strong grazing)
function water.set_reflection_params(strength, fresnel_power)
	constants.reflection_params.x = strength
	constants.reflection_params.y = fresnel_power or 3.0
end

--- Get reflection parameters
-- @return strength, fresnel_power
function water.get_reflection_params()
	return constants.reflection_params.x, constants.reflection_params.y
end

-- Note: Cubemap reflection functions currently not functional
-- TODO: Implement proper cubemap texture handle passing mechanism

--- Set skybox cubemap path for reflections (CURRENTLY NOT FUNCTIONAL)
-- @param cubemap_path Path to the cubemap texture (e.g., "/main/skybox.cubemap")
-- @deprecated This function does not work - cubemap paths cannot be used with render.enable_texture()
function water.set_skybox_cubemap(cubemap_path)
	print("WARNING: water.set_skybox_cubemap() is not functional - cubemap reflections not yet supported")
end

--- Get skybox cubemap path (CURRENTLY NOT FUNCTIONAL)
-- @return cubemap_path or nil if not set
-- @deprecated This function does not work - cubemap paths cannot be used with render.enable_texture()
function water.get_skybox_cubemap()
	return nil
end

-- ============================================================================
-- LOD PARAMS SETTERS AND GETTERS
-- ============================================================================

--- Set LOD (Level of Detail) parameters
-- @param sparkle_distance Max distance for sparkle effect (0-500, default: 100)
--        Pixels beyond this distance skip sparkle calculation (saves 8 texture samples)
-- @param foam_distance Max distance for full-quality foam (0-500, default: 150)
--        Pixels beyond this distance use simplified foam (saves 3 texture samples)
function water.set_lod_params(sparkle_distance, foam_distance)
	constants.lod_params.x = sparkle_distance
	constants.lod_params.y = foam_distance
end

--- Get LOD parameters
-- @return sparkle_distance, foam_distance
function water.get_lod_params()
	return constants.lod_params.x, constants.lod_params.y
end

return water

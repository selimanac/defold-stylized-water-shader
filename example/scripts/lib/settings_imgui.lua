local style       = require("example.scripts.lib.imgui_style")
local data        = require("example.scripts.lib.data")
local water       = require("water.water")

-- =======================================
-- MODULE
-- =======================================
local graph_imgui = {}

-- =======================================
-- Window Callback
-- =======================================
local function window_callback(self, event, data)
	if event == window.WINDOW_EVENT_FOCUS_LOST then
		--	print("window.WINDOW_EVENT_FOCUS_LOST")
	elseif event == window.WINDOW_EVENT_FOCUS_GAINED then
		--print("window.WINDOW_EVENT_FOCUS_GAINED")
	elseif event == window.WINDOW_EVENT_ICONFIED then
		--	print("window.WINDOW_EVENT_ICONFIED")
	elseif event == window.WINDOW_EVENT_DEICONIFIED then
		--	print("window.WINDOW_EVENT_DEICONIFIED")
	elseif event == window.WINDOW_EVENT_RESIZED then
		-- NO EFFECT?
		imgui.set_display_size(data.width, data.height)
	end
end

-- =======================================
-- Init
-- =======================================
function graph_imgui.init()
	local w = sys.get_config_int("display.width", 1280)
	local h = sys.get_config_int("display.height", 720)
	imgui.set_display_size(w, h)
	imgui.set_ini_filename("water_editor.ini")
	style.set()
	window.set_listener(window_callback)
end

local function colors_tab()
	local colors_tab_open = imgui.begin_tab_item("COLORS")
	if colors_tab_open then
		local r, g, b = water.get_shallow_color()
		local col = vmath.vector4(r, g, b, 1)
		imgui.color_edit4("shallow_color", col)
		water.set_shallow_color(col.x, col.y, col.z)


		r, g, b = water.get_deep_color()
		col = vmath.vector4(r, g, b, 1)
		imgui.color_edit4("deep_color", col)
		water.set_deep_color(col.x, col.y, col.z)

		r, g, b = water.get_far_color()
		col = vmath.vector4(r, g, b, 1)
		imgui.color_edit4("far_color", col)
		water.set_far_color(col.x, col.y, col.z)

		r, g, b = water.get_sun_color()
		col = vmath.vector4(r, g, b, 1)
		imgui.color_edit4("sun_color", col)
		water.set_sun_color(col.x, col.y, col.z)

		r, g, b = water.get_sparkle_color()
		col = vmath.vector4(r, g, b, 1)
		imgui.color_edit4("sparkle_color", col)
		water.set_sparkle_color(col.x, col.y, col.z)


		r, g, b = water.get_edge_foam_color()
		col = vmath.vector4(r, g, b, 1)
		imgui.color_edit4("edge_foam_color", col)
		water.set_edge_foam_color(col.x, col.y, col.z)

		imgui.end_tab_item()
	end
end

local function waves_tab()
	local waves_tab_open = imgui.begin_tab_item("WAVES")
	if waves_tab_open then
		imgui.text_colored("WAVE 1", 1, 0, 0, 1)
		imgui.separator()

		-- @param direction Wave direction in radians (0-2π)
		-- @param amplitude Wave height (0.1-0.5 gentle, 0.5-1.0 medium, 1.0-2.0 rough, 2.0+ storm)
		-- @param wavelength Distance between wave peaks (10-20 choppy, 20-40 ocean, 40+ gentle swells)
		-- @param speed Animation speed (0.5-1.0 slow, 1.0-3.0 moderate, 3.0-5.0 fast, 5.0+ very fast)
		local wave1_direction, wave1_amplitude, wave1_wavelength, wave1_speed = water.get_wave1()

		imgui.set_next_item_width(50)
		local changed_direction, direction_val = imgui.drag_float("direction##wave1", wave1_direction,
			0.01, 0.0, 2.0, 2)
		if changed_direction then
			water.set_wave1(direction_val, wave1_amplitude, wave1_wavelength, wave1_speed)
		end

		imgui.same_line()
		imgui.set_next_item_width(50)
		local changed_amplitude, amplitude_val = imgui.drag_float("amplitude##wave1", wave1_amplitude,
			0.01, 0.0, 5.0, 1)
		if changed_amplitude then
			water.set_wave1(wave1_direction, amplitude_val, wave1_wavelength, wave1_speed)
		end

		imgui.set_next_item_width(50)
		local changed_wavelength, wavelength_val = imgui.drag_float("wavelength##wave1", wave1_wavelength,
			0.01, 0.0, 100.0, 1)
		if changed_wavelength then
			water.set_wave1(wave1_direction, wave1_amplitude, wavelength_val, wave1_speed)
		end

		imgui.same_line()
		imgui.set_next_item_width(50)
		local changed_speed, speed_val = imgui.drag_float("speed##wave1", wave1_speed,
			0.01, 0.0, 20.0, 1)
		if changed_speed then
			water.set_wave1(wave1_direction, wave1_amplitude, wave1_wavelength, speed_val)
		end



		imgui.text_colored("WAVE 2", 1, 0, 0, 1)
		imgui.separator()

		-- @param direction Wave direction in radians (0-2π)
		-- @param amplitude Wave height (0.1-0.5 gentle, 0.5-1.0 medium, 1.0-2.0 rough, 2.0+ storm)
		-- @param wavelength Distance between wave peaks (10-20 choppy, 20-40 ocean, 40+ gentle swells)
		-- @param speed Animation speed (0.5-1.0 slow, 1.0-3.0 moderate, 3.0-5.0 fast, 5.0+ very fast)
		local wave2_direction, wave2_amplitude, wave2_wavelength, wave2_speed = water.get_wave2()

		imgui.set_next_item_width(50)
		local changed_direction, direction_val = imgui.drag_float("direction##wave2", wave2_direction,
			0.01, 0.0, 2.0, 2)
		if changed_direction then
			water.set_wave2(direction_val, wave2_amplitude, wave2_wavelength, wave2_speed)
		end

		imgui.same_line()
		imgui.set_next_item_width(50)
		local changed_amplitude, amplitude_val = imgui.drag_float("amplitude##wave2", wave2_amplitude,
			0.01, 0.0, 5.0, 1)
		if changed_amplitude then
			water.set_wave2(wave2_direction, amplitude_val, wave2_wavelength, wave2_speed)
		end

		imgui.set_next_item_width(50)
		local changed_wavelength, wavelength_val = imgui.drag_float("wavelength##wave2", wave2_wavelength,
			0.01, 0.0, 100.0, 1)
		if changed_wavelength then
			water.set_wave2(wave2_direction, wave2_amplitude, wavelength_val, wave2_speed)
		end

		imgui.same_line()
		imgui.set_next_item_width(50)
		local changed_speed, speed_val = imgui.drag_float("speed##wave2", wave2_speed,
			0.01, 0.0, 20.0, 1)
		if changed_speed then
			water.set_wave2(wave2_direction, wave2_amplitude, wave2_wavelength, speed_val)
		end


		imgui.text_colored("WAVE NORMAL", 1, 0, 0, 1)
		imgui.separator()

		-- @param scale Normal map tiling (5.0 large ripples, 10.0 medium, 20.0 tiny)
		-- @param speed Animation speed (0.5 slow, 1.0 normal, 2.0 fast)
		local wave_normal_scale, wave_normal_speed = water.get_wave_normal_params()
		imgui.set_next_item_width(50)
		local changed_wave_normal_scale, wave_normal_scale_val = imgui.drag_float("scale##wavenormal", wave_normal_scale,
			0.01, 0.1, 50.0, 1)
		if changed_wave_normal_scale then
			water.set_wave_normal_params(wave_normal_scale_val, wave_normal_speed)
		end

		imgui.same_line()
		imgui.set_next_item_width(50)
		local changed_wave_normal_speed, wave_normal_speed_val = imgui.drag_float("speed##wavenormal", wave_normal_speed,
			0.01, 0.1, 3.0, 1)
		if changed_wave_normal_speed then
			water.set_wave_normal_params(wave_normal_scale, wave_normal_speed_val)
		end

		imgui.end_tab_item()
	end
end

local function foam_tab()
	local foam_tab_open = imgui.begin_tab_item("FOAM")
	if foam_tab_open then
		imgui.text_colored("WATER FOAM", 1, 0, 0, 1)
		imgui.separator()
		-- @param scale Foam texture tiling (lower = bigger foam patches)
		-- @param speed Animation speed
		-- @param noise_scale Normal map distortion (0.0 no distortion, 0.5 moderate, 1.0 heavy)
		-- @param contribution Overall foam visibility (0.0 no foam, 0.5 subtle, 1.0 full)
		local foam_scale, foam_speed, foam_noise_scale, foam_contribution = water.get_foam_params()


		imgui.set_next_item_width(50)
		local changed_foam_scale, foam_scale_val = imgui.drag_float("scale##foam", foam_scale,
			0.1, 1.0, 100.0, 0.1)
		if changed_foam_scale then
			water.set_foam_params(foam_scale_val, foam_speed, foam_noise_scale, foam_contribution)
		end

		imgui.same_line()

		imgui.set_next_item_width(50)
		local changed_foam_speed, foam_speed_val = imgui.drag_float("speed##foam", foam_speed,
			0.01, 0.0, 10.0, 1)
		if changed_foam_speed then
			water.set_foam_params(foam_scale, foam_speed_val, foam_noise_scale, foam_contribution)
		end

		imgui.set_next_item_width(50)
		local changed_foam_noise_scale, foam_noise_scale_val = imgui.drag_float("noise_scale##foam", foam_noise_scale,
			0.01, 0.0, 2.0, 1)
		if changed_foam_noise_scale then
			water.set_foam_params(foam_scale, foam_speed, foam_noise_scale_val, foam_contribution)
		end

		imgui.same_line()

		imgui.set_next_item_width(50)
		local changed_foam_contribution, foam_contribution_val = imgui.drag_float("foam_contribution##foam", foam_contribution,
			0.01, 0.0, 1.0, 1)
		if changed_foam_contribution then
			water.set_foam_params(foam_scale, foam_speed, foam_noise_scale, foam_contribution_val)
		end

		imgui.text_colored("EDGE FOAM", 1, 0, 0, 1)
		imgui.separator()



		imgui.set_next_item_width(50)

		local edge_foam_type = water.get_edge_foam_type()
		local changed_edge_foam_type, edge_foam_type_val = imgui.checkbox("foam_textured##edgefoam", edge_foam_type == 1)
		if changed_edge_foam_type then
			water.set_edge_foam_type(edge_foam_type_val and 1 or 0)
		end

		-- @param depth_scale Depth scale for edge foam (how quickly foam fades with depth)
		-- @param noise_strength
		-- @param edge_softness
		-- @param alpha

		local edge_foam_depth_scale, edge_foam_noise_strength, edge_foam_edge_softness, edge_foam_alpha = water.get_edge_foam_params()

		imgui.set_next_item_width(50)
		local changed_edge_foam_depth_scale, edge_foam_depth_scale_val = imgui.drag_float("depth_scale##edgefoam", edge_foam_depth_scale,
			0.01, 0.0, 10.0, 1)
		if changed_edge_foam_depth_scale then
			water.set_edge_foam_params(edge_foam_depth_scale_val, edge_foam_noise_strength, edge_foam_edge_softness, edge_foam_alpha)
		end

		imgui.same_line()

		imgui.set_next_item_width(50)
		local changed_edge_foam_noise_strength, edge_foam_noise_strength_val = imgui.drag_float("noise_strength##edgefoam", edge_foam_noise_strength,
			0.01, 0.0, 1.0, 2)
		if changed_edge_foam_noise_strength then
			water.set_edge_foam_params(edge_foam_depth_scale, edge_foam_noise_strength_val, edge_foam_edge_softness, edge_foam_alpha)
		end

		imgui.set_next_item_width(50)
		local changed_edge_foam_edge_softness, edge_foam_edge_softness_val = imgui.drag_float("edge_softness##edgefoam", edge_foam_edge_softness,
			0.01, 0.0, 0.5, 2)
		if changed_edge_foam_edge_softness then
			water.set_edge_foam_params(edge_foam_depth_scale, edge_foam_noise_strength, edge_foam_edge_softness_val, edge_foam_alpha)
		end

		imgui.same_line()

		imgui.set_next_item_width(50)
		local changed_edge_foam_alpha, edge_foam_alpha_val = imgui.drag_float("alpha##edgefoam", edge_foam_alpha,
			0.01, 0.0, 1.0, 2)
		if changed_edge_foam_alpha then
			water.set_edge_foam_params(edge_foam_depth_scale, edge_foam_noise_strength, edge_foam_edge_softness, edge_foam_alpha_val)
		end

		imgui.end_tab_item()
	end
end

local function sparkle_tab(...)
	local sparkles_tab_open = imgui.begin_tab_item("SPARKLES")
	if sparkles_tab_open then
		-- Sparkle enable/disable toggle
		local sparkle_enabled = water.is_sparkle_enabled()
		local changed_enabled, enabled_val = imgui.checkbox("Enable Sparkles", sparkle_enabled)
		if changed_enabled then
			if enabled_val then
				water.enable_sparkle()
			else
				water.disable_sparkle()
			end
		end

		imgui.separator()

		-- @param scale Sparkle texture tiling
		-- @param speed Animation speed
		-- @param exponent Sharpness/intensity (1000 soft, 10000 medium, 100000 sharp/few)
		local sparkle_scale, sparkle_speed, sparkle_exponent, sparkle_enabled_param = water.get_sparkle_params()

		imgui.set_next_item_width(50)
		local changed_sparkle_scale, sparkle_scale_val = imgui.drag_float("sparkle_scale", sparkle_scale,
			0.01, 0.1, 100.0, 1)
		if changed_sparkle_scale then
			water.set_sparkle_params(sparkle_scale_val, sparkle_speed, sparkle_exponent)
		end

		imgui.set_next_item_width(50)
		local changed_sparkle_speed, sparkle_speed_val = imgui.drag_float("sparkle_speed", sparkle_speed,
			0.01, 0.1, 5.0, 1)
		if changed_sparkle_speed then
			water.set_sparkle_params(sparkle_scale, sparkle_speed_val, sparkle_exponent)
		end

		imgui.set_next_item_width(50)
		local changed_sparkle_exponent, sparkle_exponent_val = imgui.drag_float("sparkle_exponent", sparkle_exponent,
			0.1, 0.0, 100000.0, 0.1)
		if changed_sparkle_exponent then
			water.set_sparkle_params(sparkle_scale, sparkle_speed, sparkle_exponent_val)
		end

		-- density_params
		imgui.end_tab_item()
	end
end

local function others_tab()
	local others_tab_open = imgui.begin_tab_item("OTHERS")
	if others_tab_open then
		-- @param exponent Sun specular sharpness (100 soft, 1000 medium, 10000 sharp)
		local sun_exponent = water.get_sun_params()

		imgui.set_next_item_width(150)
		local changed_sun_exponent, sun_exponent_val = imgui.drag_float("sun_exponent", sun_exponent,
			0.1, 0.0, 10000.0, 0.1)
		if changed_sun_exponent then
			water.set_sun_params(sun_exponent_val)
		end


		-- @param distance_density Fade to far_color rate (0.01 very slow, 0.1 normal, 0.5 quick)
		-- @param depth_density Water depth color blending intensity. Higher values = faster transition from shallow to deep color

		local distance_density, depth_density = water.get_density_params()
		imgui.set_next_item_width(150)
		local changed_distance_density, distance_density_val = imgui.drag_float("distance_density", distance_density,
			0.01, 0.01, 0.5, 2)
		if changed_distance_density then
			water.set_density_params(distance_density_val, depth_density)
		end

		imgui.set_next_item_width(150)
		local changed_depth_density, depth_density_val = imgui.drag_float("depth_density", depth_density,
			0.01, 0.01, 3, 2)
		if changed_depth_density then
			water.set_density_params(distance_density, depth_density_val)
		end

		imgui.separator()
		imgui.text_colored("LOD (Level of Detail)", 1, 0, 0, 1)

		-- LOD parameters
		local sparkle_distance, foam_distance = water.get_lod_params()

		imgui.set_next_item_width(150)
		local changed_sparkle_distance, sparkle_distance_val = imgui.drag_float("sparkle_distance", sparkle_distance,
			1.0, 0.0, 500.0, 1)
		if changed_sparkle_distance then
			water.set_lod_params(sparkle_distance_val, foam_distance)
		end

		imgui.set_next_item_width(150)
		local changed_foam_distance, foam_distance_val = imgui.drag_float("foam_distance", foam_distance,
			1.0, 0.0, 500.0, 1)
		if changed_foam_distance then
			water.set_lod_params(sparkle_distance, foam_distance_val)
		end

		imgui.end_tab_item()
	end
end

local function refraction_reflection_tab()
	local refraction_reflection_tab_open = imgui.begin_tab_item("REFRACTION & REFLECTION")
	if refraction_reflection_tab_open then
		imgui.text("REFRACTION")
		imgui.separator()

		-- Refraction parameters
		local refraction_strength, chromatic_aberration = water.get_refraction_params()

		imgui.set_next_item_width(150)
		local changed_refraction_strength, refraction_strength_val = imgui.drag_float("refraction_strength", refraction_strength,
			0.01, 0.0, 1.0, 2)
		if changed_refraction_strength then
			water.set_refraction_params(refraction_strength_val, chromatic_aberration)
		end

		imgui.set_next_item_width(150)
		local changed_chromatic_aberration, chromatic_aberration_val = imgui.drag_float("chromatic_aberration", chromatic_aberration,
			0.01, 0.0, 1.0, 2)
		if changed_chromatic_aberration then
			water.set_refraction_params(refraction_strength, chromatic_aberration_val)
		end

		imgui.text("REFLECTION")
		imgui.separator()

		-- Reflection parameters
		local reflection_strength, fresnel_power = water.get_reflection_params()

		imgui.set_next_item_width(150)
		local changed_reflection_strength, reflection_strength_val = imgui.drag_float("reflection_strength", reflection_strength,
			0.01, 0.0, 1.0, 2)
		if changed_reflection_strength then
			water.set_reflection_params(reflection_strength_val, fresnel_power)
		end

		imgui.set_next_item_width(150)
		local changed_fresnel_power, fresnel_power_val = imgui.drag_float("fresnel_power", fresnel_power,
			0.1, 1.0, 5.0, 1)
		if changed_fresnel_power then
			water.set_reflection_params(reflection_strength, fresnel_power_val)
		end

		imgui.end_tab_item()
	end
end

local function settings_window()
	imgui.set_next_window_size(475, 755)
	imgui.begin_window("SETTINGS", nil)

	imgui.begin_tab_bar("tabs")

	colors_tab()
	waves_tab()
	foam_tab()
	sparkle_tab()
	refraction_reflection_tab()
	others_tab()

	imgui.end_tab_bar()

	imgui.end_window()
end

-- =======================================
-- Imgui Update
-- =======================================
function graph_imgui.update()
	data.want_mouse_input = imgui.want_mouse_input()
	settings_window()
end

return graph_imgui

#version 140

precision mediump float;

// DEBUGS
// #define DEBUG_REFLECTION
// #define DEBUG_FRESNEL
// #define DEBUG_FRESNEL_REFLECTION
// #define DEBUG_FRESNEL_BLEND

in mediump vec2     var_texcoord0;
in highp vec3       var_world_position;
in mediump vec3     var_world_normal;
in vec4             var_clip_position;

out vec4            fragColor;

uniform sampler2D   wave_normal_map;
uniform sampler2D   foam_texture;
uniform sampler2D   edge_foam_texture;
uniform sampler2D   depth_texture;
uniform sampler2D   sparkle_normal_map;
uniform sampler2D   refraction_texture;
uniform samplerCube reflection_cubemap;

const vec3          up_normal = vec3(0.0, 1.0, 0.0);

uniform fp_uniforms
{
    // Camera and Time (frequently updated)
    mediump vec4 camera_pos; // xyz: position, w: unused
    mediump vec4 time;       // x: current time, yzw: unused

    // Wave normal parameters: x: scale, y: speed, zw: unused
    mediump vec4 wave_normal_params;

    // Base colors
    mediump vec4 shallow_color;
    mediump vec4 deep_color;
    mediump vec4 far_color;

    // Foam parameters: x: scale, y: speed, z: noise_scale, w: contribution
    mediump vec4 foam_params;

    // Depth and distance: x: distance_density, y: depth_density, zw: unused
    mediump vec4 density_params;

    // Edge foam: x: depth_scale, y: unused, zw: unused
    lowp vec4    edge_foam_type;
    mediump vec4 edge_foam_params;
    mediump vec4 edge_foam_color;

    // Sun parameters: x: specular_exponent, yzw: unused
    mediump vec4 sun_params;
    mediump vec4 sun_color;
    mediump vec4 sun_direction;

    // Sparkle parameters: x: scale, y: speed, z: exponent, w: enabled (0.0 or 1.0)
    mediump vec4 sparkle_params;
    mediump vec4 sparkle_color;

    // Projection parameters: x: near, y: far, zw: unused
    mediump vec4 projection_params;

    // Refraction parameters: x: strength, y: chromatic_aberration, zw: unused
    mediump vec4 refraction_params;

    // Reflection parameters: x: strength, y: fresnel_power, zw: unused
    mediump vec4 reflection_params;

    // LOD parameters: x: sparkle_distance, y: foam_distance, zw: unused
    mediump vec4 lod_params;
};

#define PI 3.1415926536

// UV panning helper
vec2 panner(vec2 uv, vec2 direction, float speed)
{
    return uv + normalize(direction) * speed * time.x;
}

// Unpack normal
vec3 unpack_normal(vec4 packed)
{
    vec3 normal;
    normal.xy = packed.xy * 2.0 - 1.0;
    normal.z = sqrt(max(0.0, 1.0 - dot(normal.xy, normal.xy)));
    return normalize(normal);
}

// Motion four-way chaos for normals
vec3 motion_four_way_chaos_normal(sampler2D tex, vec2 uv, float speed)
{
    vec2 uv1 = panner(uv + vec2(0.000, 0.000), vec2(0.1, 0.1), speed);
    vec2 uv2 = panner(uv + vec2(0.418, 0.355), vec2(-0.1, -0.1), speed);
    vec2 uv3 = panner(uv + vec2(0.865, 0.148), vec2(-0.1, 0.1), speed);
    vec2 uv4 = panner(uv + vec2(0.651, 0.752), vec2(0.1, -0.1), speed);

    vec3 sample1 = unpack_normal(texture(tex, uv1));
    vec3 sample2 = unpack_normal(texture(tex, uv2));
    vec3 sample3 = unpack_normal(texture(tex, uv3));
    vec3 sample4 = unpack_normal(texture(tex, uv4));

    return normalize(sample1 + sample2 + sample3 + sample4);
}

// Motion four-way chaos for regular textures
vec3 motion_four_way_chaos_texture(sampler2D tex, vec2 uv, float speed)
{
    vec2 uv1 = panner(uv + vec2(0.000, 0.000), vec2(0.1, 0.1), speed);
    vec2 uv2 = panner(uv + vec2(0.418, 0.355), vec2(-0.1, -0.1), speed);
    vec2 uv3 = panner(uv + vec2(0.865, 0.148), vec2(-0.1, 0.1), speed);
    vec2 uv4 = panner(uv + vec2(0.651, 0.752), vec2(0.1, -0.1), speed);

    vec3 sample1 = texture(tex, uv1).rgb;
    vec3 sample2 = texture(tex, uv2).rgb;
    vec3 sample3 = texture(tex, uv3).rgb;
    vec3 sample4 = texture(tex, uv4).rgb;

    return (sample1 + sample2 + sample3 + sample4) / 4.0;
}

// foam for distant pixels
vec3 motion_simple_foam(sampler2D tex, vec2 uv, float speed)
{
    vec2 uv1 = panner(uv, vec2(0.1, 0.1), speed);
    return texture(tex, uv1).rgb;
}

// Sparkles
vec3 motion_four_way_sparkle(sampler2D tex, vec2 uv, vec4 coord_scale, float speed)
{
    vec2 uv1 = panner(uv * coord_scale.x, vec2(0.1, 0.1), speed);
    vec2 uv2 = panner(uv * coord_scale.y, vec2(-0.1, -0.1), speed);
    vec2 uv3 = panner(uv * coord_scale.z, vec2(-0.1, 0.1), speed);
    vec2 uv4 = panner(uv * coord_scale.w, vec2(0.1, -0.1), speed);

    vec3 sample1 = unpack_normal(texture(tex, uv1));
    vec3 sample2 = unpack_normal(texture(tex, uv2));
    vec3 sample3 = unpack_normal(texture(tex, uv3));
    vec3 sample4 = unpack_normal(texture(tex, uv4));

    vec3 normalA = vec3(sample1.x, sample2.y, 1.0);
    vec3 normalB = vec3(sample3.x, sample4.y, 1.0);

    return normalize(vec3((normalA + normalB).xy, (normalA * normalB).z));
}

// TBN matrix construction from world normal -> https://learnopengl.com/Advanced-Lighting/Normal-Mapping
// https://discussions.unity.com/t/unity-tbn-matrix-and-bent-normal/516466
mat3 get_tbn_matrix(vec3 world_normal)
{
    vec3 up = vec3(0.0, 1.0, 0.0);
    vec3 tangent = normalize(cross(up, world_normal));
    vec3 binormal = normalize(cross(world_normal, tangent));
    return mat3(tangent, binormal, world_normal);
}

// Convert non-linear depth buffer value to linear eye-space depth
// https://discussions.unity.com/t/lineareyedepth-and-linear01depth-in-a-compute-shader-returning-infinity/673801
float linear_eye_depth(float depth_sample, float near, float far)
{
    // For perspective projection, depth is non-linear
    // This converts it back to linear eye-space depth
    float z_n = 2.0 * depth_sample - 1.0; // Convert to NDC [-1, 1]
    float z_eye = 2.0 * near * far / (far + near - z_n * (far - near));
    return z_eye;
}

float saturate(float x)
{
    return clamp(x, 0.0, 1.0);
}

void main()
{
    vec2 texCoord = var_texcoord0;

    // Calculate view direction
    vec3 view_dir = normalize(var_world_position - camera_pos.xyz);

    // Build TBN matrix
    mat3 tbn = get_tbn_matrix(var_world_normal);

    // Sample wave normal map
    vec2 normal_uv = var_world_position.xz / wave_normal_params.x;
    vec3 normal_ts = motion_four_way_chaos_normal(wave_normal_map, normal_uv, wave_normal_params.y);
    vec3 normal_ws = tbn * normal_ts;

    // Distance mask for fading (using density_params.x for distance_density)
    float distance_to_camera = length(var_world_position - camera_pos.xyz);
    float distance_mask = exp(-density_params.x * distance_to_camera);

    // ------------------------------ //
    // SAMPLE DEPTH BUFFER FOR EDGE FOAM //
    // ------------------------------ //

    // Calculate screen coordinates from clip space position
    vec2 screen_coord = (var_clip_position.xy / var_clip_position.w) * 0.5 + 0.5;

    // Sample depth buffer
    float scene_depth_raw = texture(depth_texture, screen_coord).r;
    float water_depth_raw = gl_FragCoord.z;

    // Convert to linear eye-space depth
    float scene_depth = linear_eye_depth(scene_depth_raw, projection_params.x, projection_params.y);
    float water_depth = linear_eye_depth(water_depth_raw, projection_params.x, projection_params.y);

    // Calculate optical depth (distance underwater)
    // Use max to ensure positive values when scene geometry is in front of water
    float optical_depth = max(0.0, scene_depth - water_depth);

    // ---------- //
    // BASE COLOR //
    // ---------- //

    // Calculate transmittance for depth-based coloring (Unity approach)
    // Clamp to avoid complete transparency and ensure deep water shows at 50% minimum
    float transmittance = exp(-density_params.y * optical_depth);
    transmittance = max(0.5, transmittance);

    // Base color blending matching Unity's approach
    // Start with shallow, blend to deep based on transmittance, then blend to far based on distance
    vec3 base_color = shallow_color.rgb;
    base_color = mix(deep_color.rgb, base_color, transmittance);
    base_color = mix(far_color.rgb, base_color, distance_mask);

    // ------------ //
    // REFRACTION //
    // ------------ //

    vec3 refraction_color = vec3(0.0);
    if (refraction_params.x > 0.0)
    {
        // Distort screen coordinates based on water normal
        vec2 distortion = normal_ws.xy * refraction_params.x * 0.1;
        vec2 refract_coord = screen_coord + distortion;

        // Clamp to screen bounds to avoid sampling outside
        refract_coord = clamp(refract_coord, vec2(0.0), vec2(1.0));

        // Sample refraction texture with optional chromatic aberration
        if (refraction_params.y > 0.0)
        {
            // Chromatic aberration: sample RGB channels with slight offsets
            float aberration = refraction_params.y * 0.01;
            float r = texture(refraction_texture, refract_coord + vec2(aberration, 0.0)).r;
            float g = texture(refraction_texture, refract_coord).g;
            float b = texture(refraction_texture, refract_coord - vec2(aberration, 0.0)).b;
            refraction_color = vec3(r, g, b);
        }
        else
        {
            refraction_color = texture(refraction_texture, refract_coord).rgb;
        }

        // Blend refraction with base color based on optical depth
        // Deeper water shows less refraction (more of base color)
        float refraction_blend = exp(-optical_depth * 0.5);
        base_color = mix(base_color, refraction_color, refraction_blend * saturate(refraction_params.x));
    }

    // ------------ //
    // REFLECTION //
    // ------------ //

    vec3 reflection_color = vec3(0.0);
    if (reflection_params.x > 0.0)
    {
        // Calculate reflection vector for cubemap sampling (use perturbed normal)
        vec3 reflection_dir = reflect(view_dir, normal_ws);
        reflection_color = texture(reflection_cubemap, reflection_dir).rgb;

        // Fresnel effect:  Use UP vector since var_world_normal. y is zero
        // For flat water surface, the base normal should be (0, 1, 0)
        //  vec3  up_normal = vec3(0.0, 1.0, 0.0);
        float fresnel = pow(1.0 - saturate(dot(-view_dir, up_normal)), reflection_params.y);

        // Blend reflection with base color using fresnel and strength
        base_color = mix(base_color, reflection_color, fresnel * reflection_params.x);
    }

    // ---------- //
    // FOAM COLOR //
    // ---------- //

    // LOD: Use simplified foam for distant pixels (1 sample instead of 4)
    vec2 foam_uv = (var_world_position.xz / foam_params.x) + (foam_params.z * normal_ts.xz);
    vec3 foam_color;
    if (distance_to_camera < lod_params.y)
    {
        // Close range: Full quality foam with 4 texture samples
        foam_color = motion_four_way_chaos_texture(foam_texture, foam_uv, foam_params.y);
    }
    else
    {
        // Far range: Simplified foam with 1 texture sample
        foam_color = motion_simple_foam(foam_texture, foam_uv, foam_params.y);
    }
    foam_color *= distance_mask * foam_params.w;

    // ------------------ //
    // SUN SPECULAR COLOR //
    // ------------------ //

    vec3  reflected_view = reflect(view_dir, normal_ws);
    float sun_specular_mask = saturate(dot(reflected_view, sun_direction.xyz));
    sun_specular_mask = pow(sun_specular_mask, sun_params.x);
    sun_specular_mask = round(sun_specular_mask); // pow([0,1], positive) stays in [0,1]
    vec3 sun_specular = sun_color.rgb * sun_specular_mask;

    // ------------- //
    // SPARKLE COLOR //
    // ------------- //

    vec3 sparkle = vec3(0.0);

    // Only calculate sparkle if enabled AND within LOD distance
    // LOD: Skip sparkle for distant pixels to save 8 texture samples
    if (sparkle_params.w > 0.5 && distance_to_camera < lod_params.x)
    {
        vec3 sparkle1 = motion_four_way_sparkle(
        sparkle_normal_map, var_world_position.xz / sparkle_params.x, vec4(1.0, 2.0, 3.0, 4.0), sparkle_params.y);
        vec3 sparkle2 = motion_four_way_sparkle(
        sparkle_normal_map, var_world_position.xz / sparkle_params.x, vec4(1.0, 0.5, 2.5, 2.0), sparkle_params.y);

        // Sparkle calculation with scalar component products
        float sparkle_mask = dot(sparkle1, sparkle2) *
        saturate(3.0 * sqrt(saturate(sparkle1.x * sparkle2.x)));
        sparkle_mask = pow(saturate(sparkle_mask), sparkle_params.z); // pow([0,1], positive) stays in [0,1]
        sparkle_mask = ceil(sparkle_mask) * distance_mask;
        sparkle = sparkle_color.rgb * sparkle_mask;
    }

    // --------------- //
    // EDGE FOAM COLOR //
    // --------------- //

    float edge_foam_mask = 0.0;
    if (edge_foam_type.x == 0.0)
    {
        // 1. Version

        // Edge foam calculation matching Unity
        // Add small epsilon to prevent division by zero and reduce flickering
        float foam_depth_factor = optical_depth / max(0.01, edge_foam_params.x);
        edge_foam_mask = exp(-foam_depth_factor);

        // Use smoothstep instead of round for smoother transitions and less flickering
        // This creates a more gradual edge while still maintaining definition
        edge_foam_mask = smoothstep(0.4, 0.6, edge_foam_mask);

        vec3 edge_foam = edge_foam_color.rgb * edge_foam_mask;
    }

    else
    {
        // 2. Version
        float foam_depth_factor = optical_depth / max(0.01, edge_foam_params.x);
        float edge_foam_base = exp(-foam_depth_factor);

        vec2  foam_sample_uv = var_world_position.xz / (foam_params.x * 0.5);
        float foam_variation = texture(edge_foam_texture, foam_sample_uv).r;

        float noise_strength = edge_foam_params.y; // ~0.2–0.5
        float edge_softness = edge_foam_params.z;  // ~0.02–0.15

        float foam_threshold =
        0.5 + (foam_variation - 0.5) * noise_strength;

        edge_foam_mask = smoothstep(foam_threshold - edge_softness, foam_threshold + edge_softness, edge_foam_base);

        vec3 edge_foam = edge_foam_color.rgb * edge_foam_mask;
    }

    // ----------- //
    // FINAL COLOR //
    // ----------- //

#ifdef DEBUG_REFLECTION
    // Use unpurturbed normal for clean reflection view

    vec3 clean_reflection_dir = reflect(view_dir, up_normal); // normalize(var_world_normal) --up_normal
    vec3 clean_reflection = texture(reflection_cubemap, clean_reflection_dir).rgb;
    fragColor = vec4(clean_reflection, 1.0);
    return;
#endif

#ifdef DEBUG_FRESNEL
    // Use UP vector as the correct water surface normal
    // vec3  up_normal = vec3(0.0, 1.0, 0.0);
    vec3  to_camera = normalize(camera_pos.xyz - var_world_position);

    float NdotV = saturate(dot(up_normal, to_camera));
    float fresnel = pow(1.0 - NdotV, 5.0);

    // Show fresnel gradient (should be dark at top view, bright at grazing angles)
    fragColor = vec4(vec3(fresnel), 1.0);
    return;
#endif

#ifdef DEBUG_FRESNEL_REFLECTION
    // Use UP vector for fresnel
    //  vec3 up_normal = vec3(0.0, 1.0, 0.0);
    vec3 to_camera = normalize(camera_pos.xyz - var_world_position);

    // Use unpurturbed UP normal for clean reflection view
    vec3 clean_reflection_dir = reflect(view_dir, up_normal);
    vec3 clean_reflection = texture(reflection_cubemap, clean_reflection_dir).rgb;

    // Calculate fresnel
    float fresnel = pow(1.0 - saturate(dot(up_normal, to_camera)), 5.0);

    // Show fresnel effect on reflection
    fragColor = vec4(clean_reflection * fresnel, 1.0);
    return;
#endif

#ifdef DEBUG_FRESNEL_BLEND
    // Use UP vector for fresnel
    // vec3 up_normal = vec3(0.0, 1.0, 0.0);
    vec3 to_camera = normalize(camera_pos.xyz - var_world_position);

    // Use unpurturbed UP normal for clean reflection view
    vec3 clean_reflection_dir = reflect(view_dir, up_normal);
    vec3 clean_reflection = texture(reflection_cubemap, clean_reflection_dir).rgb;

    // Calculate fresnel
    float fresnel = pow(1.0 - saturate(dot(up_normal, to_camera)), 5.0);

    // Blend base color to reflection based on fresnel
    vec3 base = vec3(0.0, 0.2, 0.4); // Some base water color
    fragColor = vec4(mix(base, clean_reflection, fresnel), 1.0);
    return;
#endif

    // vec3 final_color = base_color + foam_color + sun_specular + sparkle + edge_foam;

    vec3 final_color =
    base_color +
    foam_color +
    sun_specular +
    sparkle +
    edge_foam_color.rgb * (edge_foam_mask * edge_foam_params.w);

    fragColor = vec4(final_color, 1.0);
}
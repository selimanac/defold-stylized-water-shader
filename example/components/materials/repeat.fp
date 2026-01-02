#version 140

in highp vec4             var_position;
in mediump vec3           var_normal;
in mediump vec2           var_texcoord0;
in mediump vec4           var_light;

out vec4                  out_fragColor;

uniform mediump sampler2D tex0;

uniform fs_uniforms
{
    mediump vec4 uv_repeat;
};

void main()
{
    // Repeat the texture coordinates
    mediump vec2 uv = fract(var_texcoord0 * uv_repeat.xy);

    // Sample texture with repeated UVs
    vec4 color = texture(tex0, uv);

    vec3 ambient_light = vec3(0.4, 0.4, 0.5);
    vec3 diff_light = vec3(normalize(var_light.xyz - var_position.xyz));
    diff_light = max(dot(var_normal, diff_light), 0.0) + ambient_light;
    diff_light = clamp(diff_light, 0.0, 1.0);

    out_fragColor = vec4(color.rgb * diff_light, 1.0);
}

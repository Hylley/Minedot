shader_type canvas_item;

uniform float blur: hint_range(0.0, 5.0);
uniform float grain = 0.1;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

float get_noise(vec2 uv)
{
    return fract(sin(dot(uv ,vec2(12.9898,78.233))) * 43758.5453);
}

void fragment()
{
	float n = 0.;

	if(grain > 0.)
	{
		n = 2.0 * get_noise(UV) - 1.0;
	}

	COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur) + n * grain;
}
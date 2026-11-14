shader_type canvas_item;
uniform float join_width = 0.166667;
uniform float atlas_width = 1.0;
uniform vec3 color_balance = vec3(1.0);
void fragment() {
	vec2 local_uv = vec2(UV.x / atlas_width, UV.y);
	COLOR.rgb *= color_balance;
	vec3 subdued = vec3(0.07) + (COLOR.rgb - vec3(0.07)) * 0.48;
	float grey = dot(subdued, vec3(0.299, 0.587, 0.114));
	subdued = mix(vec3(grey), subdued, 0.55);
	COLOR.rgb = mix(COLOR.rgb, subdued, smoothstep(0.55, 0.77, local_uv.y));
	if (join_width > 0.0) COLOR.a *= smoothstep(0.0, join_width, local_uv.x);
}

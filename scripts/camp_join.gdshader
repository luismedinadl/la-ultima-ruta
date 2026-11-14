shader_type canvas_item;
// Color-grade painted foreground gravel and blend PNG edges; no procedural objects.
uniform float join_width = 0.12;
void fragment() {
    vec3 subdued = vec3(0.07) + (COLOR.rgb - vec3(0.07)) * 0.48;
    float grey = dot(subdued, vec3(0.299, 0.587, 0.114));
    subdued = mix(vec3(grey), subdued, 0.55);
    COLOR.rgb = mix(COLOR.rgb, subdued, smoothstep(0.55, 0.77, UV.y));
    if (join_width > 0.0) COLOR.a *= smoothstep(0.0, join_width, UV.x);
}

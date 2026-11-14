shader_type canvas_item;
// Recolor the existing arrow artwork while preserving its outline and alpha.
void fragment() {
	float brightness = max(COLOR.r, max(COLOR.g, COLOR.b));
	COLOR.rgb = vec3(1.0, 0.12, 0.08) * brightness;
}

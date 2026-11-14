shader_type canvas_item;
// Two prone zombie frames overlap their neighbors' bounding boxes.
// Exclude only those neighboring texels; source artwork stays untouched.
uniform float alpha_cutoff = 0.0;
uniform int excluded_count = 0;
uniform vec4 excluded_rects[256];
void fragment() {
    if (texture(TEXTURE, UV).a < alpha_cutoff) discard;
    for (int i = 0; i < excluded_count; i++) {
        vec4 r = excluded_rects[i];
        if (UV.x >= r.x && UV.y >= r.y && UV.x < r.z && UV.y < r.w) discard;
    }
}

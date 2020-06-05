shader_type canvas_item;

uniform sampler2D frames: hint_albedo;
uniform float count;
uniform float duration;
uniform float width;

void fragment() {
	float frame = floor(mod(TIME, count * duration) / duration);
	float offset = floor(UV.x / width);
	COLOR = texture(frames, UV + vec2((mod(offset + frame, count) - offset) * width, 0));
}

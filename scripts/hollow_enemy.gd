class_name HollowEnemy
extends MetroEnemy
const ART := "enemies/hollow"
func _init() -> void:
	allow_basic_variants = false
	max_health = 128
	speed_multiplier = 1.45
	damage_override = 26
	attack_windup = 0.43
	attack_duration = 0.82
	attack_interval = 1.2
	attack_start_distance = 32
	attack_reach = 40
func _ready() -> void:
	super._ready()
	health_bar.position.y = -78
	alert_icon.position.y = -90
func animate(next: String) -> void:
	action = next
	sprite.sprite_frames = ContainmentArt.frames(ART)
	var factor := ContainmentArt.size_scale(ART)
	sprite.scale = Vector2.ONE*factor
	sprite.position = Vector2(0,-144*factor if next == "death" else -ContainmentArt.ground(ART,direction))
	sprite.flip_h = direction > 4
	(sprite.material as ShaderMaterial).set_shader_parameter("alpha_cutoff",0.72)
	sprite.play(next+"_"+str(direction))
	if next == "idle":
		sprite.set_frame_and_progress(0,0)
		sprite.pause()
func sync_sprite_anchor() -> void:
	sprite.offset = Vector2.ZERO
func attack_started() -> void:
	level.audio.cue("hollow",-16)

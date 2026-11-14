class_name InfectedDog
extends MetroEnemy
## Rare fast attacker. Uses metro perception and navigation; future routes can reuse it.
func _init() -> void:
	allow_basic_variants = false
	max_health = 93 # 110 HP with the metro's existing 1.18 difficulty multiplier.
	speed_multiplier = 4.0
	damage_override = 24
	attack_windup = 0.28
	attack_duration = 0.65
	attack_interval = 1.25
	attack_start_distance = 32.0
	attack_reach = 39.0

func _ready() -> void:
	super._ready()
	health_bar.position.y = -60
	alert_icon.position.y = -74

func animate(next: String) -> void:
	action = next
	sprite.sprite_frames = DogArt.frames()
	sprite.scale = Vector2.ONE*DogArt.SCALE
	sprite.position = Vector2(0,-128*DogArt.SCALE if next == "death" else -DogArt.ground_offset(direction))
	sprite.flip_h = direction > 4
	(sprite.material as ShaderMaterial).set_shader_parameter("alpha_cutoff",0.72)
	sprite.play(next+"_"+str(direction))
	if next == "idle":
		sprite.set_frame_and_progress(0,0.0)
		sprite.pause()

func sync_sprite_anchor() -> void:
	# Every dog frame already carries its stable body pivot in its atlas margin.
	sprite.offset = Vector2.ZERO

func death_sound() -> String:
	return "dog_death"

func attack_started() -> void:
	level.audio.cue("dog_bite",-15)

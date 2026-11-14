class_name ShotgunPlayer
extends RoutePlayer
## Separate ammunition pools. Base movement, knife and pistol retain their behaviour.
const ART := "characters/nico_shotgun"
const SHELL_CAPACITY := 4
const MAX_SHELL_RESERVE := 12
var has_shotgun := false
var weapon_slot := 1 # knife / pistol / shotgun
var shells := 0
var shell_reserve := 0
func acquire_shotgun() -> void:
	if has_shotgun: return
	has_shotgun = true
	shells = 4
	shell_reserve = 8
	weapon_slot = 2
	pistol_equipped = true
	action_time = 0
	animate("idle")
func animate(next: String) -> void:
	if weapon_slot != 2:
		super.animate(next)
		return
	action = next
	lateral_walk_active = false
	sprite.sprite_frames = ContainmentArt.frames(ART,true)
	var factor := ContainmentArt.size_scale(ART)
	sprite.scale = Vector2.ONE*factor
	sprite.position = Vector2(0,-144*factor if next == "death" else -ContainmentArt.ground(ART,direction))
	sprite.flip_h = direction > 4
	sprite.offset = Vector2.ZERO
	(sprite.material as ShaderMaterial).set_shader_parameter("alpha_cutoff",0.72)
	sprite.play(next+"_"+str(direction))
	if next == "idle":
		sprite.set_frame_and_progress(0,0)
		sprite.pause()
func switch_weapon() -> void:
	if dead or level.blocked or action_time > 0: return
	weapon_slot = (weapon_slot+1) % (3 if has_shotgun else 2)
	pistol_equipped = weapon_slot != 0
	switch_target = pistol_equipped
	animate("equip" if pistol_equipped else "idle")
	action_time = 0.32
func begin_reload() -> void:
	if weapon_slot != 2:
		super.begin_reload()
		return
	if dead or level.blocked or action_time > 0 or shells >= SHELL_CAPACITY or shell_reserve <= 0: return
	animate("reload")
	action_time = 1.6
	level.audio.cue("reload_shotgun",-12)
func complete_reload() -> void:
	if weapon_slot != 2:
		super.complete_reload()
		return
	var amount := mini(SHELL_CAPACITY-shells,shell_reserve)
	shells += amount
	shell_reserve -= amount
func fire_pistol() -> void:
	if weapon_slot != 2:
		super.fire_pistol()
		return
	if shells <= 0:
		if shell_reserve > 0: begin_reload()
		else: level.audio.cue("empty",-17)
		return
	if not RouteControls.touch_mode and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		facing = (get_global_mouse_position()-position-Vector2(0,-20)).normalized()
	else:
		facing = level.assisted_aim(position,210,facing)
	if facing == Vector2.ZERO: facing = Vector2.RIGHT
	direction = RouteControls.direction_index(facing)
	shells -= 1
	animate("shoot")
	action_time = 0.85
	level.shotgun_shot(self)

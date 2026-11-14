class_name RouteAudio
extends Node
## Audio cues use their final asset names; ambience is looped independently.

var ambience: AudioStreamPlayer
var music: AudioStreamPlayer
const MUSIC_SETTINGS := "user://music.cfg"
var music_percent := 100
var saved_music_percent := 100
var track_volume_db := -8.0
const CUE_FILES := {
	"death_nico":"death_nico.ogg",
	"zombie":"zombie.ogg", "anclado_death":"anclado_death.ogg",
	"death":"death.ogg", "resistant_death":"resistant_death.ogg",
	"dog_bite":"dog_bite.ogg", "dog_death":"dog_death.ogg",
	"dog_growl":"dog_growl.ogg", "empty":"empty.ogg",
	"hollow":"hollow.ogg", "anclado":"anclado.ogg",
	"hurt":"hurt.ogg", "pistol":"pistol.ogg",
	"reload_shotgun":"reload_shotgun.ogg", "shotgun":"shotgun.ogg"
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	ambience = AudioStreamPlayer.new()
	add_child(ambience)
	music = AudioStreamPlayer.new()
	add_child(music)
	var settings := ConfigFile.new()
	if settings.load(MUSIC_SETTINGS) == OK:
		music_percent = clampi(int(settings.get_value("music","percent",100)),0,100)
	saved_music_percent = music_percent
	set_route_ambience(-1)

func set_music_percent(value: int) -> void:
	music_percent = clampi(value, 0, 100)
	music.volume_linear = db_to_linear(track_volume_db) * music_percent / 100.0

func save_music_volume() -> void:
	if saved_music_percent == music_percent: return
	var settings := ConfigFile.new()
	settings.set_value("music", "percent", music_percent)
	if settings.save(MUSIC_SETTINGS) == OK: saved_music_percent = music_percent

func cue(name_: String, volume: float = -9.0, pitch: float = 1.0) -> void:
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = load("res://assets/audio/" + str(CUE_FILES.get(name_,name_+".wav")))
	player.volume_db = volume
	player.pitch_scale = pitch
	player.finished.connect(player.queue_free)
	player.play()

func _exit_tree() -> void:
	# Stop looping streams explicitly so test/headless audio servers release them.
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null

# -1: menu; 0: introduction; 1-8: playable levels.
func set_route_ambience(number: int) -> void:
	# Music has its own player: indoor rain fades must not mute the score.
	var in_level := number >= 1 and number <= 8
	var rain := load("res://assets/audio/rain.ogg") as AudioStreamOggVorbis
	rain.loop = true
	rain.loop_offset = 0.0
	ambience.stream = rain
	ambience.volume_db = -17.0
	ambience.play()
	ambience.stream_paused = number in [-1, 3]
	if in_level:
		var suspense := load("res://assets/audio/leberchsuspense_loop.ogg") as AudioStreamOggVorbis
		suspense.loop = true
		suspense.loop_offset = 0.0
		music.stream = suspense
		track_volume_db = -15.0
	elif number == -1:
		var menu_track := load("res://assets/audio/lost.ogg") as AudioStreamOggVorbis
		menu_track.loop = true
		menu_track.loop_offset = 0.0
		music.stream = menu_track
		track_volume_db = -8.0
	else:
		var drone := load("res://assets/audio/drone.wav") as AudioStreamWAV
		drone.loop_mode = AudioStreamWAV.LOOP_FORWARD
		drone.loop_end = roundi(drone.get_length()*drone.mix_rate)
		music.stream = drone
		track_volume_db = -22.0
	set_music_percent(music_percent)
	music.stream_paused = false
	music.play()

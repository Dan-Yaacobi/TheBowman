class_name Game extends Node2D

@onready var game_manager: GameManager = $GameManager

const CLOUD = preload("res://MainGame/Clouds/Cloud.tscn")
@onready var game_music: AudioStreamPlayer = $GameMusic
@onready var cloud_timer: Timer = $CloudTimer
@onready var hud: HUD = $Hud

@onready var sky: ColorRect = $CanvasLayer/ColorRect

const MAIN_MENU = preload("uid://cnhbrpo4htp2y")
var main_menu: PackedScene = MAIN_MENU

@export var music_on: bool = true :
	set(val):
		music_on = val
		if is_node_ready():
			music_on_off()

@export_group("Music")
## Hub / main menu world.
@export var menu_music: AudioStream
@export var rift_music: AudioStream
## Boss arenas and boss events, from the moment the fight starts.
@export var boss_music: AudioStream
## Event scenes (golden apple, jump quest...). Boss events switch to boss_music once the fight starts.
@export var event_music: AudioStream
@export var music_volume_db: float = -8.0
## Seconds to fade out the old track and fade in the new one.
@export var music_fade: float = 0.8
@export_group("")

const MUSIC_SILENT_DB: float = -40.0
var _current_track: AudioStream
var _music_tween: Tween

var player: Player
var last_scene: Node

func _ready() -> void:
	EventBus.change_sky_color.connect(change_sky_colors)
	game_manager.set_game(self)
	game_manager.change_game_world(GameWorlds.worlds.Main_Menu)
	PlayerManager.player.health_bar = hud.get_health_bar()
	cloud_timer.timeout.connect(summon_cloud)
	cloud_timer.start()
	add_child(PlayerManager.player)
	EventBus.world_ready.connect(_play_world_music)
	EventBus.event_exited.connect(_play_world_music)
	EventBus.event_entered.connect(_on_event_entered)
	EventBus.boss_fight_started.connect(_on_boss_fight_started)

func summon_cloud() -> void:
	var new_cloud: Cloud = CLOUD.instantiate()
	new_cloud.global_position = PlayerManager.player.global_position + Vector2(-500, randf_range(-200, -50))
	
	var depth = randf_range(0.3, 1.0)
	new_cloud.scale = Vector2.ONE * depth
	new_cloud.move_speed = lerp(10.0, 40.0, depth)
	
	add_child(new_cloud)
	cloud_timer.wait_time = randf_range(1, 5)
	
func music_on_off() -> void:
	if music_on:
		var track: AudioStream = _current_track
		_current_track = null
		_play_track(track)
	else:
		if _music_tween:
			_music_tween.kill()
		game_music.stop()

# --- Music ----------------------------------------------------------------

## Menu track in the hub, rift track everywhere else (boss arenas start on it until the fight).
func _play_world_music() -> void:
	if game_manager.curr_world is MainMenu:
		_play_track(menu_music)
	else:
		_play_track(rift_music)

func _on_event_entered() -> void:
	_play_track(event_music)

func _on_boss_fight_started(_boss: Boss) -> void:
	_play_track(boss_music)

## Fades the current track out and the new one in. Same track = keep playing. Null = fade to silence.
func _play_track(track: AudioStream) -> void:
	if track == _current_track and game_music.playing:
		return
	_current_track = track
	if not music_on:
		return
	if _music_tween:
		_music_tween.kill()
	# Fades keep running while the tree is paused (transitions, menus), like the music itself.
	_music_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if game_music.playing:
		_music_tween.tween_property(game_music, "volume_db", MUSIC_SILENT_DB, music_fade * 0.5)
	_music_tween.tween_callback(_start_track.bind(track))
	if track:
		_music_tween.tween_property(game_music, "volume_db", music_volume_db, music_fade * 0.5)

func _start_track(track: AudioStream) -> void:
	game_music.stop()
	if track == null:
		return
	# Music files are imported without looping; loop them here.
	var wav: AudioStreamWAV = track as AudioStreamWAV
	if wav:
		if wav.loop_mode == AudioStreamWAV.LOOP_DISABLED:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = roundi(wav.get_length() * wav.mix_rate)
	elif "loop" in track:
		track.set("loop", true)
	game_music.stream = track
	game_music.volume_db = MUSIC_SILENT_DB
	game_music.play()

func change_sky_colors(sky_colors: SkyColors) -> void:
	var mat: ShaderMaterial = sky.material as ShaderMaterial
	if mat == null:
		push_warning("Sky ColorRect has no ShaderMaterial")
		return
	mat.set_shader_parameter("color_top", sky_colors.top_color)
	mat.set_shader_parameter("color_bottom", sky_colors.bottom_color)
	_set_clouds_enabled(sky_colors.show_clouds)

## Off clears the clouds already in the sky (sky changes happen behind the transition fade).
func _set_clouds_enabled(enabled: bool) -> void:
	if enabled:
		if cloud_timer.is_stopped():
			cloud_timer.start()
		return
	cloud_timer.stop()
	for child: Node in get_children():
		if child is Cloud:
			child.queue_free()

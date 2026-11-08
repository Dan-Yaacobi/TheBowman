extends Node2D

@onready var arrow_shot: AudioStreamPlayer2D = $ArrowShot
@onready var coin_drop: AudioStreamPlayer2D = $CoinDrop
@onready var arrow_twang: AudioStreamPlayer2D = $ArrowTwang
@onready var arrow_hit_wall: AudioStreamPlayer2D = $ArrowHitWall
@onready var string_pull: AudioStreamPlayer2D = $StringPull
@onready var arrow_release: AudioStreamPlayer2D = $ArrowRelease
@onready var object_destroyed: AudioStreamPlayer2D = $ObjectDestroyed
@onready var sword_slash: AudioStreamPlayer2D = $SwordSlash
@onready var click: AudioStreamPlayer2D = $Click

@export var jump_stream: AudioStream
@export var jump_volume_db: float = -6.0
## One is picked at random per step.
@export var footstep_streams: Array[AudioStream] = []
@export var footstep_volume_db: float = -14.0
@export var click_volume_db: float = -4.0
@export var portal_stream: AudioStream
@export var portal_volume_db: float = -4.0
## Holding "up" at a portal re-triggers enter(); one sound per this many seconds.
const PORTAL_SOUND_COOLDOWN_MS: int = 1000
var _last_portal_sound_ms: int = -PORTAL_SOUND_COOLDOWN_MS
@export var draw_volume_db: float = -4.0
## Pitch limits when stretching the draw sound to the draw time (very fast/slow draws).
@export var draw_pitch_min: float = 0.6
@export var draw_pitch_max: float = 2.0
@export var draw_fade_out: float = 0.08

var _draw_tween: Tween

func _ready() -> void:
	EventBus.arrow_hit_sound.connect(arrow_hit_sound)
	EventBus.arrow_shot_sound.connect(arrow_shot_sound)
	EventBus.coin_drop_sound.connect(coin_drop_sound)
	EventBus.button_click_sound.connect(button_click_sound)
	EventBus.arrow_hit_wall_sound.connect(arrow_hit_wall_sound)
	EventBus.string_pull_sound.connect(string_pull_sound)
	EventBus.string_pull_stop.connect(string_pull_stop)
	EventBus.arrow_release_sound.connect(arrow_release_sound)
	EventBus.object_destroyed_sound.connect(object_destroyed_sound)
	EventBus.enemy_died_sound.connect(enemy_died_sound)
	EventBus.sword_slash_sound.connect(sword_slash_sound)
	EventBus.play_any.connect(play_any)
	EventBus.jump_sound.connect(jump_sound)
	EventBus.footstep_sound.connect(footstep_sound)
	EventBus.portal_entered_sound.connect(portal_entered_sound)

## The players here are 2D and fade with distance from the camera. Events sit far from the
## world origin (GameWorld.event_offset), so staying at the camera keeps every sound audible.
func _process(_delta: float) -> void:
	var camera: Camera2D = get_viewport().get_camera_2d()
	if camera:
		global_position = camera.get_screen_center_position()

func enemy_died_sound(_audio: AudioStream) -> void:
	_play_oneshot(_audio,0.5,0.5,-3)
	
func sword_slash_sound() -> void:
	_play_oneshot(sword_slash.stream,0.8,1.2,-2)
	
func object_destroyed_sound() -> void:
	_play_oneshot(object_destroyed.stream, 0.5,1.5, -10)
	
func arrow_release_sound(_pitch: float) -> void:
	arrow_release.play()

## Plays the draw over exactly the draw time: faster pulls play it quicker and higher.
func string_pull_sound(draw_duration: float) -> void:
	if _draw_tween:
		_draw_tween.kill()
	var length: float = string_pull.stream.get_length()
	string_pull.pitch_scale = clampf(length / maxf(draw_duration, 0.01), draw_pitch_min, draw_pitch_max)
	string_pull.volume_db = draw_volume_db
	string_pull.play()

## Released or cancelled mid-draw: short fade so it doesn't click.
func string_pull_stop() -> void:
	if not string_pull.playing:
		return
	if _draw_tween:
		_draw_tween.kill()
	_draw_tween = create_tween()
	_draw_tween.tween_property(string_pull, "volume_db", -40.0, draw_fade_out)
	_draw_tween.tween_callback(string_pull.stop)
	
func coin_drop_sound() -> void:
	_play_oneshot(coin_drop.stream, 0.9, 1.2)

func arrow_hit_sound() -> void:
	_play_oneshot(arrow_hit_wall.stream, 2.0, 3.0, 5.0)

func arrow_hit_wall_sound() -> void:
	_play_oneshot(arrow_hit_wall.stream, 1.5, 2.0)
	
func arrow_shot_sound() -> void:
	_play_oneshot(arrow_shot.stream)

func button_click_sound() -> void:
	_play_oneshot(click.stream, 0.95, 1.05, click_volume_db)

func jump_sound() -> void:
	_play_oneshot(jump_stream, 0.95, 1.1, jump_volume_db)

func footstep_sound() -> void:
	if footstep_streams.is_empty():
		return
	_play_oneshot(footstep_streams.pick_random(), 0.9, 1.1, footstep_volume_db)

func portal_entered_sound() -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_portal_sound_ms < PORTAL_SOUND_COOLDOWN_MS:
		return
	_last_portal_sound_ms = now
	_play_oneshot(portal_stream, 0.97, 1.03, portal_volume_db)

func play_any(stream: AudioStream, pitch_min: float, pitch_max: float, volume: float) -> void:
	_play_oneshot(stream,pitch_min, pitch_max, volume)
	
func _play_oneshot(stream: AudioStream, pitch_min: float = 1.0, pitch_max: float = 1.0, volume: float = 0.0) -> void:
	if stream == null:
		return
	var player := AudioStreamPlayer2D.new()
	add_child(player)
	player.stream = stream
	player.volume_db = volume
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.finished.connect(player.queue_free)
	player.play()

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

func enemy_died_sound(_audio: AudioStream) -> void:
	_play_oneshot(_audio,0.5,0.5,-3)
	
func sword_slash_sound() -> void:
	_play_oneshot(sword_slash.stream,0.8,1.2,-2)
	
func object_destroyed_sound() -> void:
	_play_oneshot(object_destroyed.stream, 0.5,1.5, -10)
	
func arrow_release_sound(pitch: float) -> void:
	arrow_release.play()

func string_pull_sound(pitch: float) -> void:
	string_pull.pitch_scale = pitch
	_play_oneshot(string_pull.stream,pitch,pitch)

func string_pull_stop() -> void:
	string_pull.stop()
	
func coin_drop_sound() -> void:
	_play_oneshot(coin_drop.stream, 0.9, 1.2)

func arrow_hit_sound() -> void:
	_play_oneshot(arrow_hit_wall.stream, 2.0, 3.0, 5.0)

func arrow_hit_wall_sound() -> void:
	_play_oneshot(arrow_hit_wall.stream, 1.5, 2.0)
	
func arrow_shot_sound() -> void:
	_play_oneshot(arrow_shot.stream)

func button_click_sound() -> void:
	_play_oneshot(click.stream,1.0,1.0,30)
	
func _play_oneshot(stream: AudioStream, pitch_min: float = 1.0, pitch_max: float = 1.0, volume: float = 0.0) -> void:
	var player := AudioStreamPlayer2D.new()
	add_child(player)
	player.stream = stream
	player.volume_db = volume
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.finished.connect(player.queue_free)
	player.play()

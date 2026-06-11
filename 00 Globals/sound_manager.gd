extends Node2D

@onready var arrow_shot: AudioStreamPlayer2D = $ArrowShot
@onready var arrow_hit: AudioStreamPlayer2D = $ArrowHit
@onready var coin_drop: AudioStreamPlayer2D = $CoinDrop

func _ready() -> void:
	EventBus.arrow_hit_sound.connect(arrow_hit_sound)
	EventBus.arrow_shot_sound.connect(arrow_shot_sound)
	EventBus.coin_drop_sound.connect(coin_drop_sound)
	
func coin_drop_sound() -> void:
	_play_oneshot(coin_drop.stream, 0.9, 1.2)

func arrow_hit_sound() -> void:
	_play_oneshot(arrow_hit.stream, 0.4, 1.4)

func arrow_shot_sound() -> void:
	_play_oneshot(arrow_shot.stream)
	
func _play_oneshot(stream: AudioStream, pitch_min: float = 1.0, pitch_max: float = 1.0) -> void:
	var player := AudioStreamPlayer2D.new()
	add_child(player)
	player.stream = stream
	player.volume_db = -15
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.finished.connect(player.queue_free)
	player.play()

class_name IceShield
extends Node2D

const ICE_SHARD: PackedScene = preload("uid://cde2ouylndf60")

@export var shard_count: int = 6
@export var radius: float = 40.0
@export var angular_speed: float = 1.0

var _shards: Array[Node2D] = []
var _elapsed_time: float = 0.0


func _ready() -> void:
	_spawn_shards()


func _physics_process(delta: float) -> void:
	_elapsed_time += delta
	_update_shard_positions()


func _spawn_shards() -> void:
	_shards.resize(shard_count)

	for i: int in range(shard_count):
		var shard: Node2D = ICE_SHARD.instantiate()
		shard.shard_destroyed.connect(_on_shard_destroyed.bind(i))
		add_child(shard)
		_shards[i] = shard


func _on_shard_destroyed(slot_index: int) -> void:
	_shards[slot_index] = null


func _update_shard_positions() -> void:
	var angle_step: float = TAU / shard_count

	for i: int in range(_shards.size()):
		var shard: Node2D = _shards[i]
		if shard == null:
			continue

		var angle: float = _elapsed_time * angular_speed + angle_step * i
		shard.position = Vector2(cos(angle), sin(angle)) * radius

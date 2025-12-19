class_name IntroChunk extends RiftChunk
@onready var player_spawn: PlayerSpawn = $PlayerSpawn

func spawn_position() -> Vector2:
	return player_spawn.global_position

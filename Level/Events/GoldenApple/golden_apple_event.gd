class_name GoldenAppleEvent extends Event

## Snitch-style chase: hit the golden apple 5 times before time runs out.
## The exit portal is available the whole time.

@export var golden_apple: GoldenApple

@onready var falling_death: FallingDeath = $FallingDeath

var _world: GameWorld = null
var _world_respawn_position: Vector2 = Vector2.ZERO
var _zoomed_out: bool = false

func on_event_entered() -> void:
	# Falling inside the event should respawn here, not back in the rift
	_world = get_parent() as GameWorld
	if _world:
		_world_respawn_position = _world.respawn_position
		_world.respawn_position = get_event_spawn()
	PlayerManager.player.camera.zoom_out()
	_zoomed_out = true
	if is_instance_valid(golden_apple):
		golden_apple.died.connect(_on_golden_apple_died, CONNECT_ONE_SHOT)

func on_event_exited() -> void:
	if is_instance_valid(_world):
		_world.respawn_position = _world_respawn_position
	if _zoomed_out:
		PlayerManager.player.camera.zoom_in()
		_zoomed_out = false

func _on_golden_apple_died(apple: Enemy) -> void:
	spawn_rewards(apple.global_position)

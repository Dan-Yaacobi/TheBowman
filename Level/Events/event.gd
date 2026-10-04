class_name Event extends Node2D

@onready var spawn_marker: Marker2D = $SpawnMarker
@export var rewards: Array[EventReward] = []
## Horizontal gap between separate rewards so their pickups don't pile up.
@export var reward_spacing: float = 16.0

func spawn_rewards(at_position: Vector2, weight: int = 0, reward_list: Array[EventReward] = []) -> void:
	var list: Array[EventReward] = reward_list if not reward_list.is_empty() else rewards
	var eligible: Array[EventReward] = list.filter(
		func(r: EventReward) -> bool: return r.can_grant(weight)
	)
	var start_x: float = -reward_spacing * (eligible.size() - 1) * 0.5
	for i: int in eligible.size():
		eligible[i].spawn(at_position + Vector2(start_x + reward_spacing * i, 0.0))
func get_event_spawn() -> Vector2:
	return spawn_marker.global_position

## Called after the player has arrived.
func on_event_entered() -> void:
	pass

## Called right before the event is freed.
func on_event_exited() -> void:
	pass

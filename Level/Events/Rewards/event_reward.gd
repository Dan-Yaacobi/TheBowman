class_name EventReward extends Resource

## Granted only when the event's reward weight is at least this.
@export var min_weight: int = 0

func can_grant(weight: int) -> bool:
	return weight >= min_weight

## Spawns this reward's pickups at a global position.
func spawn(_position: Vector2) -> void:
	pass

## Text shown in reward previews. Rewards with identical text are merged (e.g. "Skyshard" ×2).
func get_preview_text() -> String:
	return ""

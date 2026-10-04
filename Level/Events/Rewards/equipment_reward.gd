class_name EquipmentReward extends EventReward

## -1 = normal rift-level rarity roll.
@export var forced_rarity: int = -1

func spawn(position: Vector2) -> void:
	EventBus.try_drop.emit(position, 100.0, forced_rarity)

func get_preview_text() -> String:
	return "Random equipment"

class_name EquipmentReward extends EventReward

## -1 = normal rift-level rarity roll.
@export var forced_rarity: int = -1
## Optional upgrade roll: with upgrade_chance, drops at upgrade_rarity instead.
## -1 = no upgrade. Rarity values follow EquipmentData.Rarity.
@export var upgrade_rarity: int = -1
@export_range(0.0, 1.0) var upgrade_chance: float = 0.0

func spawn(position: Vector2) -> void:
	EventBus.try_drop.emit(position, 100.0, roll_rarity())

func roll_rarity() -> int:
	if upgrade_rarity >= 0 and randf() < upgrade_chance:
		return upgrade_rarity
	return forced_rarity

func get_preview_text() -> String:
	return "Random equipment"

class_name MinorAbility extends PlayerAbility

## Lowest value at quality 0.
@export var min_value: int = 1
## Highest value at quality 0.
@export var max_value: int = 3
## Added to both min and max per quality tier. 0 = rarity has no effect.
@export var value_per_quality: int = 1

var value: int = 1

func roll_values(quality: int) -> void:
	var bonus: int = quality * value_per_quality
	value = randi_range(min_value + bonus, max_value + bonus)

class_name ItemReward extends EventReward

@export var item: CustomVariables.items
@export var display_name: String = ""
@export var min_amount: int = 1
@export var max_amount: int = 1

func spawn(position: Vector2) -> void:
	var amount: int = randi_range(min_amount, max_amount)
	EventBus.drop_item.emit(item, position, 100.0, amount)

func get_preview_text() -> String:
	return display_name

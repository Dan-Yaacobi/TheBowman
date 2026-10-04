class_name RandomItemReward extends EventReward

@export var options: Array[ItemReward] = []

func spawn(position: Vector2) -> void:
	if options.is_empty():
		return
	options.pick_random().spawn(position)

func get_preview_text() -> String:
	var names: Array[String] = []
	for option: ItemReward in options:
		names.append(option.display_name)
	if names.size() <= 1:
		return "".join(names)
	return "%s or %s" % [", ".join(names.slice(0, -1)), names[-1]]

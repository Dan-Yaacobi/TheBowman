extends FlowContainer

func _ready() -> void:
	for child in get_children():
		child.queue_free()

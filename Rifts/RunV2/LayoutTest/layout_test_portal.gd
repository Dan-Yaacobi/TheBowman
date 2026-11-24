class_name LayoutTestPortal extends EventPortal
## Debug-only hub portal: opens the test picker for a combat layout or an event node.

@export var mode: LayoutTestPicker.Mode = LayoutTestPicker.Mode.LAYOUT


func teleport_player() -> void:
	if get_tree().root.find_child("LayoutTestPicker", true, false):
		return
	var picker: LayoutTestPicker = LayoutTestPicker.new()
	picker.name = "LayoutTestPicker"
	picker.mode = mode
	get_tree().root.add_child(picker)

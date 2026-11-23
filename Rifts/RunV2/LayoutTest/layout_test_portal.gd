class_name LayoutTestPortal extends EventPortal
## Debug-only hub portal: opens the layout test picker instead of an event.


func teleport_player() -> void:
	if get_tree().root.find_child("LayoutTestPicker", true, false):
		return
	var picker: LayoutTestPicker = LayoutTestPicker.new()
	picker.name = "LayoutTestPicker"
	get_tree().root.add_child(picker)

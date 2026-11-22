class_name NodePortal extends Portal
## A crossroads portal: leads into the node it carries.

var node_data: RunNodeData


func setup(_node_data: RunNodeData) -> void:
	node_data = _node_data
	if node_data:
		color = node_data.portal_color


func enter() -> void:
	if node_data == null:
		return
	if not _has_bow_and_quiver():
		CombatTextSpawner.spawn(global_position, _missing_gear_message(), Color.WHITE)
		return
	EventBus.portal_entered_sound.emit()
	EventBus.node_portal_entered.emit(node_data)


func _leads_into_rift() -> bool:
	return node_data != null

class_name Forge extends NPC
## The blacksmith's forge. Interacting opens the craft menu; crafted items drop at drop_point.

@export var drop_point: Marker2D

func action(_index: int) -> void:
	EventBus.open_craft_menu.emit(drop_point.global_position)

## Keeps the forge from going to Gone after opening the menu.
func holds_interaction() -> bool:
	return true

## Locked after a craft, so the interact key goes to the dropped item instead.
func can_interact() -> bool:
	return not Crafting.crafted_this_run

func extra_ready_functions() -> void:
	EventBus.craft_menu_closed.connect(_on_event_bus_craft_menu_closed)
	Crafting.craft_lock_changed.connect(_on_crafting_craft_lock_changed)
	_on_crafting_craft_lock_changed(Crafting.crafted_this_run)

func _on_crafting_craft_lock_changed(locked: bool) -> void:
	keyboard_press_helper.visible = not locked

func on_interaction_closed() -> void:
	EventBus.close_craft_menu.emit()

func _on_event_bus_craft_menu_closed() -> void:
	if npc_state_machine.curr_state is NPCInteractedState:
		npc_state_machine.ChangeState($NpcStateMachine/Idle)

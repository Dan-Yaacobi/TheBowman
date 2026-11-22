class_name CombatRift extends RunNodeWorld
## A hand-made combat node. Skeleton: the exit is open; encounters and the exit lock come next.

@onready var exit_portal: Portal = $ExitPortal
@onready var loot_manager: LootManager = $LootManager


func extra_node_set_functions() -> void:
	loot_manager.set_up()


func extra_node_exit_functions() -> void:
	loot_manager.unset_up()


func _on_world_ready() -> void:
	EventBus.entered_rift.emit()

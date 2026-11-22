class_name RestNode extends RunNodeWorld
## A calm node with one helper NPC (cleric, rogue wizard or pirate) and an open exit.

@onready var loot_manager: LootManager = $LootManager


func extra_node_set_functions() -> void:
	# The pirate's gamble drops through the loot manager.
	loot_manager.set_up()


func extra_node_exit_functions() -> void:
	loot_manager.unset_up()

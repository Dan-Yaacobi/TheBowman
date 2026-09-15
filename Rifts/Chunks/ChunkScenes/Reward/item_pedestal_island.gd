class_name ItemPedestalIsland extends RiftChunk

@onready var pedestal_npc_3: PedestalNPC = $Island/PedestalNPC3
@onready var pedestal_npc_2: PedestalNPC = $Island2/PedestalNPC2
@onready var pedestal_npc: PedestalNPC = $Island3/PedestalNPC

var pedestals: Array[PedestalNPC] = []

func extra_ready_functions() -> void:
	pedestals.append(pedestal_npc)
	pedestals.append(pedestal_npc_2)
	pedestals.append(pedestal_npc_3)

	for pedestal in pedestals:
		pedestal.picked.connect(reset_pedestals)

	call_deferred("_try_set_items")

func _try_set_items() -> void:
	if not is_inside_tree() or is_queued_for_deletion():
		return
	set_items()
	
func reset_pedestals(pedestal_picked: PedestalNPC) -> void:
	for pedestal in pedestals:
		if pedestal != pedestal_picked:
			pedestal.disable()
			
func set_items() -> void:
	var items: Array[EquipmentData] = GameStateManager.current_loot_manager.roll_distinct_items(pedestals.size())
	for i in pedestals.size():
		if i < items.size():
			pedestals[i].set_item(items[i])

class_name RogueWizard extends NPC
## A rogue wizard who defied the cult, met on a reward island (once per run, from the snow
## biome on). Reforges one equipped item: it's unequipped and destroyed, then dropped again
## rerolled one rarity higher. Costs essence by the rarity it goes to. One reforge per visit.

## Essence to reach each rarity (Common, Uncommon, Epic, Legendary). Index 0 is never used.
@export var costs_by_rarity: Array[int] = [0, 20, 40, 80]
## Where the reforged item drops.
@export var drop_point: Marker2D

var _menu_open: bool = false


func extra_ready_functions() -> void:
	EventBus.reforge_slot_chosen.connect(_on_event_bus_reforge_slot_chosen)
	EventBus.reforge_menu_closed.connect(_on_event_bus_reforge_menu_closed)


func action(_index: int) -> void:
	if action_taken:
		return
	_menu_open = true
	EventBus.open_reforge_menu.emit(costs_by_rarity)


## Keeps the chat open while the reforge window is up.
func holds_interaction() -> bool:
	return true


func _on_event_bus_reforge_slot_chosen(slot: int) -> void:
	if not _menu_open or action_taken:
		return
	var player: Player = PlayerManager.player
	var item: EquipmentData = player.get_equipped_in_slot(slot as EquipmentData.slots)
	if item == null or item.rarity >= item.max_rarity():
		return
	var new_rarity: int = item.rarity + 1
	if new_rarity >= costs_by_rarity.size():
		return
	if not player.buy(costs_by_rarity[new_rarity], CustomVariables.items.ESSENCE):
		return
	player.destroy_equipped(slot as EquipmentData.slots)
	var at: Vector2 = drop_point.global_position if drop_point else global_position
	EventBus.drop_specific_item.emit(item, at, new_rarity)
	action_taken = true
	keyboard_press_helper.hide()
	play_one_shot("action")
	show_post_action_line()


func _on_event_bus_reforge_menu_closed() -> void:
	_menu_open = false


func on_interaction_opened() -> void:
	play_one_shot("interacted")

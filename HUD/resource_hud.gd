class_name ResourceHud extends Control

@onready var coin: ItemHud = $HBoxContainer5/Coin
@onready var wood: ItemHud = $HBoxContainer5/Wood
@onready var essence: ItemHud = $HBoxContainer5/Essence
@onready var sky_shard: ItemHud = $HBoxContainer5/SkyShard
## Run tally for the disenchanting table. Hidden until the table is built.
@onready var found_items: ItemHud = $HBoxContainer5/FoundItems

@onready var _huds: Dictionary[CustomVariables.items, ItemHud] = {
	CustomVariables.items.COIN: coin,
	CustomVariables.items.WOOD: wood,
	CustomVariables.items.ESSENCE: essence,
	CustomVariables.items.SKYSHARD: sky_shard,
}
func _ready() -> void:
	EventBus.found_items_changed.connect(_on_event_bus_found_items_changed)
	_refresh_all.call_deferred()

func _refresh_all() -> void:
	var items: Dictionary = PlayerManager.player.stats.items
	for item: CustomVariables.items in _huds:
		update_amount(int(items.get(item, 0)), item, false)
	_update_found_items(Disenchanting.get_count(), false)
		
## Pass animate = false when filling in saved values on load.
func update_amount(amount: int, item: CustomVariables.items, animate: bool = true) -> void:
	var hud: ItemHud = _huds.get(item)
	if hud == null:
		push_warning("ResourceHud has no ItemHud for item %s" % item)
		return
	hud.set_amount(amount, animate)

func _on_event_bus_found_items_changed(count: int) -> void:
	_update_found_items(count, true)

func _update_found_items(count: int, animate: bool) -> void:
	found_items.visible = Disenchanting.is_active()
	found_items.set_amount(count, animate and found_items.visible)


class_name ResourceHud extends Control

@onready var coin: ItemHud = $HBoxContainer5/Coin
@onready var wood: ItemHud = $HBoxContainer5/Wood
@onready var essence: ItemHud = $HBoxContainer5/Essence
@onready var sky_shard: ItemHud = $HBoxContainer5/SkyShard

@onready var _huds: Dictionary[CustomVariables.items, ItemHud] = {
	CustomVariables.items.COIN: coin,
	CustomVariables.items.WOOD: wood,
	CustomVariables.items.ESSENCE: essence,
	CustomVariables.items.SKYSHARD: sky_shard,
}
func _ready() -> void:
	_refresh_all.call_deferred()

func _refresh_all() -> void:
	var items: Dictionary = PlayerManager.player.stats.items
	for item: CustomVariables.items in _huds:
		update_amount(int(items.get(item, 0)), item, false)
		
## Pass animate = false when filling in saved values on load.
func update_amount(amount: int, item: CustomVariables.items, animate: bool = true) -> void:
	var hud: ItemHud = _huds.get(item)
	if hud == null:
		push_warning("ResourceHud has no ItemHud for item %s" % item)
		return
	hud.set_amount(amount, animate)

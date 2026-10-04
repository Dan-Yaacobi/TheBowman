extends Node

const COIN_SCENE: String = "res://Items/Other/Coin/coin.tscn"
const POTION_SCENE: String = "res://Items/Other/Potion/Potion.tscn"
const MAGIC_ESSENCE: String = "res://Items/Other/Magic Essence/MagicEssence.tscn"
const WOOD: String = "res://Items/Other/Wood/Wood.tscn"
const SKY_SHARD: String = "res://Items/Other/SkyShard/SkyShard.tscn"

@export var spread_angle: float = 50.0
@export var impulse_min: float = 10.0
@export var impulse_max: float = 40.0
@export var drop_interval: float = 0.06


var items_dic: Dictionary ={
	CustomVariables.items.COIN : COIN_SCENE,
	CustomVariables.items.POTION: POTION_SCENE,
	CustomVariables.items.ESSENCE: MAGIC_ESSENCE,
	CustomVariables.items.WOOD: WOOD,
	CustomVariables.items.SKYSHARD: SKY_SHARD
}

func drop_coins(_position: Vector2, _amount: int) -> void:
	var player_stats = PlayerManager.player.stats
	var adjusted_amount: int = _amount + player_stats.extra_gold.value()
	var count: int = _roll_coin_count(adjusted_amount)
	if count <= 0:
		return
	_spawn_sequence(_position, count, CustomVariables.items.COIN)

func drop_item(_item: CustomVariables.items, _position: Vector2, _chance: float, _amount: int = 1) -> void:
	if _item == CustomVariables.items.COIN:
		drop_coins(_position, _amount)
	else:
		if randf_range(0,100) < _chance:
			_spawn_sequence(_position, _amount, _item)
		
func drop_potion(_position: Vector2, _chance: float) -> void:
	if randf_range(0,100) < _chance:
		_spawn_sequence(_position, 1, CustomVariables.items.POTION)

func drop_essence(_position: Vector2, _chance: float) -> void:
	if randf_range(0,100) < _chance:
		_spawn_sequence(_position, 1, CustomVariables.items.ESSENCE)

func _roll_coin_count(average: int) -> int:
	var per_roll := int(average * 2.0 / 3.0)
	if per_roll == 0:
		return randi_range(0, 1)
	return randi_range(0, per_roll) + randi_range(0, per_roll) + randi_range(0, per_roll)

func _spawn_sequence(position: Vector2, count: int, _item: CustomVariables.items) -> void:
	var item_scene = load(items_dic[_item])
	for i in count:
		var item: Item = item_scene.instantiate()
		EventBus.summon_effect.emit(item)
		EventBus.coin_drop_sound.emit()
		item.global_position = position
		var angle: float = lerp(-spread_angle * 0.5, spread_angle * 0.5, float(i) / max(count - 1, 1))
		var dir: Vector2 = Vector2(sin(deg_to_rad(angle)), -1.0).normalized()
		var distance: float = randf_range(impulse_min, impulse_max)
		item.launch(position + dir * distance)
		if count > 1 and i < count - 1:
			await get_tree().create_timer(drop_interval).timeout
			if not is_inside_tree():
				return

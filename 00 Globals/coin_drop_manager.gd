extends Node

const COIN_SCENE: String = "res://Items/Other/Coin/coin.tscn"

@export var spread_angle: float = 40.0
@export var impulse_min: float = 10.0
@export var impulse_max: float = 10.0
@export var drop_interval: float = 0.06
	
func drop_coins(_position: Vector2, _amount: int) -> void:

	var player_stats = PlayerManager.player.stats
	var adjusted_amount: int = _amount + player_stats.extra_gold
	var count: int = _roll_coin_count(adjusted_amount)
	if count <= 0:
		return

	_spawn_sequence(_position, count)

func _roll_coin_count(average: int) -> int:
	var per_roll := int(average * 2.0 / 3.0)
	if per_roll == 0:
		return randi_range(0, 1)
	return randi_range(0, per_roll) + randi_range(0, per_roll) + randi_range(0, per_roll)

func _spawn_sequence(position: Vector2, count: int) -> void:
	var coin_scene = load(COIN_SCENE)
	for i in count:
		var coin: Coin = coin_scene.instantiate()
		EventBus.summon_effect.emit(coin)
		coin.global_position = position
		var angle: float = lerp(-spread_angle * 0.5, spread_angle * 0.5, float(i) / max(count - 1, 1))
		var dir: Vector2 = Vector2(sin(deg_to_rad(angle)) * 0.3, -1.0)
		var distance: float = randf_range(impulse_min, impulse_max)
		coin.launch(position + dir * distance)
		if count > 1 and i < count - 1:
			await get_tree().create_timer(drop_interval).timeout
			if not is_inside_tree():
				return

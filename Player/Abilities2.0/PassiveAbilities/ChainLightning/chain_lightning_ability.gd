class_name ChainLightningAbility extends PlayerGaugeAbility

const LIGHTNING_CHAIN = preload("uid://bf4okr84ysm2p")
const LIGHTNING = preload("uid://v43hqxcynju5")

var _hit_enemy: Enemy = null
var _hit_position: Vector2 = Vector2.ZERO

func connect_gauge() -> void:
	max_gauge = 1
	gauge_texture = LIGHTNING
	gauge_tint = Color.ORANGE
	EventBus.arrow_enemy_hit.connect(_on_arrow_hit)
	EventBus.enemy_stunned.connect(_on_enemy_stunned)
	EventBus.charge_gauge.connect(use_gauge)

func disconnect_gauge() -> void:
	EventBus.arrow_enemy_hit.disconnect(_on_arrow_hit)
	EventBus.enemy_stunned.disconnect(_on_enemy_stunned)
	EventBus.charge_gauge.disconnect(use_gauge)

func use_gauge() -> void:
	if find_target():
		_hit_position = PlayerManager.player.global_position
		activate_gauge_ability(max_gauge)
		gauge_active = false
		EventBus.gauge_charge_used.emit()

func find_target() -> bool:
	_hit_enemy = null
	var player_pos: Vector2 = PlayerManager.player.global_position
	var closest_dist_sq: float = INF
	for enemy: Enemy in PlayerManager.player.get_nearby_enemies():
		var dist_sq: float = player_pos.distance_squared_to(enemy.global_position)
		if dist_sq < closest_dist_sq:
			closest_dist_sq = dist_sq
			_hit_enemy = enemy
	return _hit_enemy != null
	
func _on_arrow_hit(_perfect: bool, _arrow: Arrow, _target: Enemy) -> void:
	if _arrow and _perfect:
		fill_gauge()
	
func _on_enemy_stunned(_enemy: Enemy) -> void:
	fill_gauge()

func activate_gauge_ability(_amount: int) -> void:
	var chain: LightningChain = LIGHTNING_CHAIN.instantiate()
	EventBus.summon_effect.emit(chain)
	chain.setup(_hit_position, _hit_enemy, chain.max_chains, [])

func get_tooltip() -> String:
	return "Perfect shots and apply stuns fill the gauge. When full, your next perfect shot chains lightning."

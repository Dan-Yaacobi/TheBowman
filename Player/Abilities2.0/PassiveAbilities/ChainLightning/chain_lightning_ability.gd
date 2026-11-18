class_name ChainLightningAbility extends PlayerGaugeAbility

const LIGHTNING_CHAIN = preload("uid://bf4okr84ysm2p")
const LIGHTNING = preload("uid://v43hqxcynju5")

## How far from the player the first bolt can reach.
@export var target_radius: float = 100.0

var _hit_enemy: Enemy = null
var _hit_position: Vector2 = Vector2.ZERO

func connect_gauge() -> void:
	max_gauge = 4
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
	# Searched by hitbox, not body: wizard bosses' bodies aren't on the Enemies layer.
	for enemy: Enemy in MinorHitHelpers.enemies_in_radius(PlayerManager.player.get_world_2d(), player_pos, target_radius):
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
	chain.damage = maxi(1, roundi(chain.damage * power()))
	EventBus.summon_effect.emit(chain)
	chain.setup(_hit_position, _hit_enemy, chain.max_chains, [])

func get_tooltip() -> String:
	return "Perfect shots and stuns fill the gauge.\n%s strike the nearest enemy with lightning that chains and stuns." % ACTIVATE_HINT

func get_tooltip_color() -> Color:
	return Color.YELLOW

class_name ChainLightningAbility extends PlayerGaugeAbility

const LIGHTNING_CHAIN = preload("uid://bf4okr84ysm2p")
const LIGHTNING = preload("uid://v43hqxcynju5")

var _hit_enemy: Enemy = null
var _hit_position: Vector2 = Vector2.ZERO

func connect_gauge() -> void:
	max_gauge = 4
	gauge_texture = LIGHTNING
	gauge_tint = Color.ORANGE
	EventBus.arrow_enemy_hit.connect(_on_arrow_hit)
	EventBus.enemy_stunned.connect(_on_enemy_stunned)
	EventBus.charge_gauge.connect(gauge_activated)

func disconnect_gauge() -> void:
	EventBus.arrow_enemy_hit.disconnect(_on_arrow_hit)
	EventBus.enemy_stunned.disconnect(_on_enemy_stunned)
	EventBus.charge_gauge.disconnect(gauge_activated)

func _on_arrow_hit(_perfect: bool, _arrow: Arrow, _enemy: Enemy) -> void:
	if _perfect and is_instance_valid(_enemy):
		_hit_position = _arrow.global_position
		_hit_enemy = _enemy
		if gauge_active:
			activate_gauge_ability(max_gauge)
			gauge_active = false
			EventBus.gauge_charge_used.emit()
		else:
			fill_gauge()
		
func _on_enemy_stunned(_enemy: Enemy) -> void:
	fill_gauge()

func activate_gauge_ability(_amount: int) -> void:
	var chain: LightningChain = LIGHTNING_CHAIN.instantiate()
	EventBus.summon_effect.emit(chain)
	chain.setup(_hit_position, _hit_enemy, chain.max_chains, [])

func get_tooltip() -> String:
	return "Perfect shots and apply stuns fill the gauge. When full, your next perfect shot chains lightning."

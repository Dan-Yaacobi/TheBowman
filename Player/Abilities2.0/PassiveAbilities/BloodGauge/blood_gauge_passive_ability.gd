class_name BloodGaugeAbility extends PlayerGaugeAbility

const BLOOD_EXPLOSION = preload("uid://dfqptnmqklf0q")
const BLOOD_DROP = preload("uid://dsb2mepij6kgu")

var explosion_position: Vector2

func connect_gauge() -> void:
	max_gauge = 5
	gauge_texture = BLOOD_DROP
	gauge_tint = Color.DARK_RED
	EventBus.arrow_enemy_hit.connect(shot_power_fill_gauge)
	PlayerManager.player.took_hit.connect(get_hit_fill_gauge)
	EventBus.arrow_enemy_hit.connect(use_gauge)
	EventBus.use_gauge.connect(activate_gauge_ability)
	EventBus.sword_hit.connect(sword_hit_fill_gauge)
	
func disconnect_gauge() -> void:
	PlayerManager.player.took_hit.disconnect(get_hit_fill_gauge)
	EventBus.arrow_enemy_hit.disconnect(shot_power_fill_gauge)
	EventBus.arrow_enemy_hit.disconnect(use_gauge)
	EventBus.use_gauge.disconnect(activate_gauge_ability)
	EventBus.sword_hit.disconnect(sword_hit_fill_gauge)

func activate_gauge_ability(_amount: int) -> void:
	var blood_explosion: BloodExplosion = BLOOD_EXPLOSION.instantiate()
	blood_explosion.global_position = explosion_position
	EventBus.summon_effect.emit(blood_explosion)

func use_gauge(_perfect: bool, _arrow: Arrow, _enemy: Enemy) -> void:
	if _arrow and _enemy and _perfect:
		explosion_position = _arrow.global_position
		EventBus.request_gauge.emit(true)
		
func sword_hit_fill_gauge(_enemy: Enemy) -> void:
	fill_gauge(0.5)
func get_hit_fill_gauge() -> void:
	fill_gauge()
func shot_power_fill_gauge(_perfect: bool, _arrow: Arrow, _enemy: Enemy) -> void:
	fill_gauge(_arrow.arrow_shot_power)

func get_tooltip() -> String:
	return "Collect Blood. When full, a perfect shot unleashes a blood explosion."

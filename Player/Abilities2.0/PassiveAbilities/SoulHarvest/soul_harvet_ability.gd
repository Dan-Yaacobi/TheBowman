class_name SoulHarvestAbility extends PlayerGaugeAbility

const SOUL = preload("uid://3kavoouowc45")
const SOULS_EXPLOSION = preload("uid://c4wv0u8011p4w")
const SOUL_TEXTURE = preload("uid://cal23t1ka4qvt")

var explosion_position: Vector2

func connect_gauge() -> void:
	max_gauge = 7
	gauge_texture = SOUL_TEXTURE
	gauge_tint = Color.AQUAMARINE
	EventBus.enemy_died.connect(summon_soul)
	EventBus.arrow_enemy_hit.connect(use_gauge)
	EventBus.use_gauge.connect(activate_gauge_ability)

func disconnect_gauge() -> void:
	EventBus.enemy_died.disconnect(summon_soul)
	EventBus.arrow_enemy_hit.disconnect(use_gauge)
	EventBus.use_gauge.disconnect(activate_gauge_ability)

func activate_gauge_ability(_amount: int) -> void:
	var new_explosion: SoulExplosion = SOULS_EXPLOSION.instantiate()
	EventBus.summon_effect.emit(new_explosion)
	new_explosion.setup(_amount)
	new_explosion.global_position = explosion_position

func use_gauge(_perfect: bool, _arrow: Arrow, _enemy: Enemy) -> void:
	if _arrow and _enemy and _perfect:
		explosion_position = _arrow.global_position
		EventBus.request_gauge.emit(false)
		
func summon_soul(_enemy: Enemy ) -> void:
	var new_soul: Soul = SOUL.instantiate()
	new_soul.global_position = _enemy.global_position
	new_soul.set_homing()
	EventBus.summon_effect.emit(new_soul)

func get_tooltip() -> String:
	return "Collect enemy souls, unleash them with your Perfect Shot"

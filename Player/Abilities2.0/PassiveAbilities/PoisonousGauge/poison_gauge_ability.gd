class_name PoisonGaugeAbility extends PlayerGaugeAbility

const POISONOUS_CLOUD = preload("uid://dml4cxyxwod76")
const POISON = preload("uid://w4hcybitvnr2")

var cloud_position: Vector2

const POISON_DEBUFF = preload("uid://dw404fcvhcw52")

var poison_ability: PoisonAbility

func connect_gauge() -> void:
	max_gauge = 10
	gauge_texture = POISON
	gauge_tint = Color.DARK_GREEN
	EventBus.activate_gauge.connect(activate_gauge_ability)
	EventBus.charge_gauge.connect(use_gauge)
	EventBus.poison_damage_dealt.connect(poison_fill)
	poison_ability = PoisonAbility.new()
	poison_ability.trigger_type = TriggerType.BEFORE_HIT
	PlayerManager.player.register_ability(poison_ability)
	
func disconnect_gauge() -> void:
	EventBus.activate_gauge.disconnect(activate_gauge_ability)
	EventBus.charge_gauge.disconnect(use_gauge)
	EventBus.poison_damage_dealt.disconnect(poison_fill)
	PlayerManager.player.unregister_ability(poison_ability)

func activate_gauge_ability(_amount: int) -> void:
	var poison_cloud: PoisonCloud = POISONOUS_CLOUD.instantiate()
	poison_cloud.global_position = cloud_position
	poison_cloud.emitting = true
	EventBus.summon_effect.emit(poison_cloud)

func use_gauge() -> void:
	cloud_position = PlayerManager.player.global_position
	activate_gauge_ability(max_gauge)
	gauge_active = false
	EventBus.gauge_charge_used.emit()
		
func poison_fill() -> void:
	fill_gauge()
	
func get_tooltip() -> String:
	return "Fills with poison, release a big gas cloud when full. Also perfect shots inflict poison."

func get_tooltip_color() -> Color:
	return Color.DARK_GREEN

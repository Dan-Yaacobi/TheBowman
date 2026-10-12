class_name PoisonDebuff extends Debuff

@export var ramp_per_tick: float = 0.2
@export var max_multiplier: float = 3.0

@export var low_color: Color = Color(0.55, 0.72, 0.42)
@export var high_color: Color = Color(0.55, 1.0, 0.05)
@export var low_speed: float = 0.6
@export var high_speed: float = 1.6
@export var high_scale: float = 3
@export var low_width: float = 6.0
@export var high_width: float = 10.0
@export var low_rise: float = 25.0
@export var high_rise: float = 75.0

@onready var poisoned_effect: CPUParticles2D = $PoisonedEffect

var poison_damage: int = 1
var elapsed_ticks: int = 0
var damage_remainder: float = 0.0
var visual_progress: float = 0.0
var visual_tween: Tween

func start_debuff_effect() -> void:
	entity.modulate = Color(0.502, 0.82, 0.392)
	apply_poison_visual(0.0)

func set_damage(_dmg: int) -> void:
	poison_damage = _dmg

func get_multiplier() -> float:
	return minf(1.0 + ramp_per_tick * elapsed_ticks, max_multiplier)

func get_ramp_progress() -> float:
	return inverse_lerp(1.0, max_multiplier, get_multiplier())

func apply_debuff_effect() -> void:
	damage_remainder += poison_damage * get_multiplier()
	var dmg: int = floori(damage_remainder)
	damage_remainder -= dmg
	elapsed_ticks += 1
	update_poison_visual()
	entity.take_damage(null, dmg, null, Color.LAWN_GREEN)
	EventBus.poison_damage_dealt.emit()

func merge(incoming: Debuff, incoming_ticks: int) -> void:
	ticks += incoming_ticks
	poison_damage = maxi(poison_damage, (incoming as PoisonDebuff).poison_damage)

func extra_end_debuff_methods() -> void:
	entity.modulate = Color(1.0, 1.0, 1.0)

func update_poison_visual() -> void:
	if visual_tween:
		visual_tween.kill()
	visual_tween = create_tween()
	visual_tween.tween_method(apply_poison_visual, visual_progress, get_ramp_progress(), tick_interval)

func apply_poison_visual(t: float) -> void:
	visual_progress = t
	var bubble_scale: float = lerpf(1.0, high_scale, t)
	poisoned_effect.speed_scale = lerpf(low_speed, high_speed, t)
	poisoned_effect.scale_amount_min = bubble_scale
	poisoned_effect.scale_amount_max = bubble_scale
	poisoned_effect.color = low_color.lerp(high_color, t)
	poisoned_effect.emission_rect_extents.x = lerpf(low_width, high_width, t)
	poisoned_effect.gravity.y = -lerpf(low_rise, high_rise, t)

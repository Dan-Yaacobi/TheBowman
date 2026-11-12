class_name VortexAbility extends PlayerAbility
## Vortex Quiver: a perfect arrow hit opens a small vortex that pulls nearby enemies together for a
## moment. Bosses and enemies that can't be knocked back aren't pulled. The radius scales with the
## quiver's color level.

@export var duration: float = 1.0
@export var radius: float = 90.0
## Pull speed toward the center, pixels per second.
@export var pull_speed: float = 130.0

func activate_ability(_target: Node2D = null, _activator: Node2D = null, _result: DamageResult = null) -> void:
	var arrow: Arrow = MinorHitHelpers.arrow_of(_activator as HurtBox)
	if arrow == null or not arrow.perfect_shot or _target == null or not _target.is_inside_tree():
		return
	var vortex: VortexField = VortexField.new()
	vortex.global_position = _target.global_position
	vortex.duration = duration
	vortex.radius = radius * power()
	vortex.pull_speed = pull_speed
	EventBus.summon_effect.emit(vortex)

func get_tooltip() -> String:
	return "Perfect hits open a vortex that pulls nearby enemies together"

func get_tooltip_color() -> Color:
	return Color(0.6, 0.55, 1.0)

func get_type() -> TriggerType:
	return TriggerType.AFTER_HIT

## The vortex itself: pulls enemies in its radius toward its center and draws a spinning swirl.
class VortexField extends Node2D:
	const COLOR: Color = Color(0.6, 0.55, 1.0)
	const ARMS: int = 3
	var duration: float = 1.0
	var radius: float = 90.0
	var pull_speed: float = 130.0
	var _age: float = 0.0

	func _ready() -> void:
		z_index = 2

	func _physics_process(delta: float) -> void:
		_age += delta
		if _age >= duration:
			queue_free()
			return
		for enemy: Enemy in MinorHitHelpers.enemies_in_radius(get_world_2d(), global_position, radius):
			if enemy.is_dead or enemy is Boss or not enemy.stats.can_be_knockedback:
				continue
			var to_center: Vector2 = global_position - enemy.global_position
			var dist: float = to_center.length()
			if dist < 2.0:
				continue
			enemy.global_position += to_center / dist * minf(pull_speed * delta, dist)
		queue_redraw()

	func _draw() -> void:
		var life: float = clampf(1.0 - _age / maxf(duration, 0.01), 0.0, 1.0)
		var spin: float = _age * 9.0
		for i: int in ARMS:
			var start: float = spin + TAU * i / ARMS
			var color: Color = COLOR
			color.a = 0.7 * life
			draw_arc(Vector2.ZERO, radius * (0.35 + 0.15 * i), start, start + 2.2, 16, color, 2.0)
		draw_circle(Vector2.ZERO, 4.0, Color(COLOR, 0.8 * life))

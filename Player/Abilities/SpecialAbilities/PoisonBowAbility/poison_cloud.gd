@tool

class_name PoisonCloud extends CPUParticles2D

@onready var area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

@export var max_radius: float = 80
@export var start_radius: float = 30:
	
	set(value):
		start_radius = value
		if collision_shape:
			collision_shape.shape.radius = start_radius
			
const POISON_DEBUFF = preload("uid://dw404fcvhcw52")

func _ready() -> void:
	collision_shape.shape.radius = start_radius
	area.body_entered.connect(poison_damage)
	
	if !Engine.is_editor_hint():
		_start_lifetime_timer()

func _start_lifetime_timer() -> void:
	var effective_duration: float = lifetime / speed_scale if speed_scale > 0.0 else lifetime
	var lifetime_timer: Timer = Timer.new()
	lifetime_timer.wait_time = effective_duration
	lifetime_timer.one_shot = true
	add_child(lifetime_timer)
	lifetime_timer.timeout.connect(queue_free)
	lifetime_timer.start()

func poison_damage(_body) -> void:
	if _body is Enemy:
		var poison: PoisonDebuff = POISON_DEBUFF.instantiate()
		poison.poison_damage = PlayerManager.player.stats.poison_damage.value()
		var duration: float = PlayerManager.player.stats.poison_duration.value()
		var ticks: int = PlayerManager.player.stats.poison_ticks.value()
		_body.apply_debuff(poison,CustomVariables.POISON_DEBUFF_ID, duration,ticks)

func _physics_process(delta: float) -> void:
	if emitting == true:
		if collision_shape.shape.radius < max_radius:
			collision_shape.shape.radius += 30*delta

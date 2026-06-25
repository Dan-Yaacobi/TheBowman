class_name PoisonCloud extends CPUParticles2D

@onready var area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

@export var poison_dmg: int
const POISON_DEBUFF = preload("uid://dw404fcvhcw52")

func _ready() -> void:
	collision_shape.shape.radius = 30
	area.body_entered.connect(poison_damage)
	
func poison_damage(_body) -> void:
	if _body is Enemy:
		var poison: PoisonDebuff = POISON_DEBUFF.instantiate()
		poison.poison_damage = poison_dmg
		_body.apply_debuff(poison, 10,5)
	pass

func _physics_process(delta: float) -> void:
	if emitting == true:
		if collision_shape.shape.radius < 75:
			collision_shape.shape.radius += 15*delta
		else:
			queue_free()

class_name PoisonCloud extends CPUParticles2D

@onready var area: Area2D = $Area2D
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

@export var poison_dmg: int
const Poisoned = preload("res://Enemies/EnemyEffects/Poisoned/poisoned.gd")

func _ready() -> void:
	collision_shape.shape.radius = 10
	area.body_entered.connect(poison_damage)
	
func poison_damage(_body) -> void:
	if _body is Enemy:
		var new_poison: PoisonEffect = PoisonEffect.new()
		new_poison.damage = poison_dmg
		_body.stats.debuffs.append(new_poison)
	pass

func _physics_process(delta: float) -> void:
	if emitting == true:
		if collision_shape.shape.radius < 45:
			collision_shape.shape.radius += 15*delta
	else:
		queue_free()

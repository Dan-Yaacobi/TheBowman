class_name ComboActivatedEffect extends CPUParticles2D

@onready var area: Area2D = $Area2D
@onready var player: Player = $"../.."
@onready var combo_activated_effect: ComboActivatedEffect = $"."
@onready var collision_shape: CollisionShape2D = $Area2D/CollisionShape2D

func _ready() -> void:
	area.body_entered.connect(detect_enemy)
	collision_shape.shape.radius = 20
	pass

func _physics_process(delta: float) -> void:
	if combo_activated_effect.emitting == true:
		area.monitoring = true
		collision_shape.shape.radius += 15*delta
	else:
		collision_shape.shape.radius = 20
		combo_activated_effect.emitting = false
		area.monitoring = false
		
func detect_enemy(b) -> void:
	if b is Enemy:
		b.take_damage(player.current_weapon.base_damage)

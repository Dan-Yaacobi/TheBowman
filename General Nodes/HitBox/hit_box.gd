class_name HitBox extends Area2D

signal Damaged( hurt_box: HurtBox, _result: DamageResult )
@export var show_damage: bool = true
var collision: CollisionShape2D
func _ready() -> void:
	for child in get_children():
		if child is CollisionShape2D:
			collision = child

func TakeDamage(hurt_box: HurtBox, _result: DamageResult = null) -> void:
	Damaged.emit(hurt_box,0, _result)
	
func change_effect_color(_color: Color) -> void:
	pass

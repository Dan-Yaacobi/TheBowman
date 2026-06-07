class_name HitBox extends Area2D

signal Damaged( hurt_box: HurtBox )
@export var show_damage: bool = true

func _ready() -> void:
	pass 

func TakeDamage(hurt_box: HurtBox) -> void:
	Damaged.emit(hurt_box)
	
func change_effect_color(_color: Color) -> void:
	pass

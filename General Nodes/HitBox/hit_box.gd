class_name HitBox extends Area2D

signal Damaged( hurt_box: HurtBox, _result: DamageResult )
@export var show_damage: bool = true

func _ready() -> void:
	pass 

func TakeDamage(hurt_box: HurtBox, _result: DamageResult = null) -> void:
	Damaged.emit(hurt_box,0, _result)
	
func change_effect_color(_color: Color) -> void:
	pass

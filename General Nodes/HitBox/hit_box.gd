class_name HitBox extends Area2D

signal Damaged( hurt_box: HurtBox )
@onready var enemy_hit_effect: EnemyHitEffect = $EnemyHitEffect
@export var show_damage: bool = true

func _ready() -> void:
	pass 

func TakeDamage(hurt_box: HurtBox) -> void:
	Damaged.emit(hurt_box)
	
func change_effect_color(_color: Color) -> void:
	if _color:
		enemy_hit_effect.set_effect_color(_color)

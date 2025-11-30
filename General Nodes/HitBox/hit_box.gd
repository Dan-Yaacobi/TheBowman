class_name HitBox extends Area2D

signal Damaged( hurt_box: HurtBox )
@onready var enemy_hit_effect: EnemyHitEffect = $EnemyHitEffect
@export var show_damage: bool = true

var enemy: Enemy
func _ready() -> void:
	if get_parent() is Enemy:
		enemy = get_parent()
	pass 

func TakeDamage(hurt_box: HurtBox) -> void:
	Damaged.emit(hurt_box)
	if enemy:
		enemy_hit_effect.hit()
		change_effect_color(hurt_box.effect_color)
		enemy.hit(hurt_box)
	if show_damage:
		CombatTextSpawner.spawn(global_position, str(hurt_box.damage),hurt_box.combat_text_color)

func change_effect_color(_color: Color) -> void:
	if _color:
		enemy_hit_effect.set_effect_color(_color)

func get_enemy() -> Enemy:
	return enemy

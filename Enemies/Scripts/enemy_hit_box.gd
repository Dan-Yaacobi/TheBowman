class_name EnemyHitBox extends HitBox

var enemy: Enemy
@onready var enemy_hit_effect: EnemyHitEffect = $EnemyHitEffect

func set_enemy(_enemy: Enemy) -> void:
	if _enemy:
		enemy = _enemy
	pass

func TakeDamage(hurt_box: HurtBox) -> void:
	Damaged.emit(hurt_box)
	if enemy:
		enemy_hit_effect.hit()
		change_effect_color(hurt_box.effect_color)
	if show_damage:
		enemy.show_damage(hurt_box.damage,hurt_box.combat_text_color)
		
func change_effect_color(_color: Color) -> void:
	if _color:
		enemy_hit_effect.set_effect_color(_color)

func get_enemy() -> Enemy:
	return enemy
	

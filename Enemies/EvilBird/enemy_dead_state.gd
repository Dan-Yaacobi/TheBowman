class_name EnemyDeadState extends EnemyState

@export var animation_name: StringName = &"Dead"

func init() -> void:
	pass

func Enter() -> void:
	_disable_collisions()
	enemy.knockback_velocity = Vector2.ZERO
	if enemy is CharacterBody2D:
		(enemy as CharacterBody2D).velocity = Vector2.ZERO
	if enemy.enemy_health_bar:
		enemy.enemy_health_bar.hide()
	var anim_player: AnimationPlayer = enemy.animation_player
	if anim_player == null or not anim_player.has_animation(animation_name):
		enemy.queue_free()
		return
	anim_player.animation_finished.connect(_on_animation_finished, CONNECT_ONE_SHOT)
	anim_player.play(animation_name)

func Exit() -> void:
	pass

func Process(_delta: float) -> EnemyState:
	return null

func Physics(_delta: float) -> EnemyState:
	return null

func _disable_collisions() -> void:
	enemy.hit_box.set_deferred("monitoring", false)
	enemy.hit_box.set_deferred("monitorable", false)
	enemy.hurt_box.set_deferred("monitoring", false)
	enemy.hurt_box.set_deferred("monitorable", false)

func _on_animation_finished(_anim_name: StringName) -> void:
	enemy.queue_free()

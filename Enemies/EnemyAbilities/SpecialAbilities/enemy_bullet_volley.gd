class_name EnemyBulletVolley extends EnemyAbility

@export var amount: int = 12
@export var interval: float = 5.0
@export var angle_offset_degrees: float = 0.0

func activate_ability(_enemy) -> void:
	if not (_enemy is Enemy and _enemy.stats.bullet):
		return
	_start_timer(_enemy)

func _start_timer(enemy: Enemy) -> void:
	enemy.get_tree().create_timer(interval).timeout.connect(_on_timer_timeout.bind(enemy))

func _on_timer_timeout(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or not enemy.is_inside_tree():
		return
	_fire_volley(enemy)
	_start_timer(enemy)

func _fire_volley(enemy: Enemy) -> void:
	if amount <= 0:
		return
	var angle_step: float = TAU / float(amount)
	var start_angle: float = deg_to_rad(angle_offset_degrees)
	for i: int in amount:
		var bullet: EnemyBullet = enemy.bullet_set_up() as EnemyBullet
		if bullet == null:
			return
		bullet.data.move_speed *= 2
		bullet.direction = Vector2.RIGHT.rotated(start_angle + angle_step * i)
		EventBus.summon_effect.emit(bullet)

class_name BirdbossTransitionState extends EnemyState

var _dropping: bool = false

@onready var roost: BirdbossRoostState = $"../Roost"
@onready var ground_ray: RayCast2D = null

func init() -> void:
	ground_ray = (enemy as BirdBoss).ground_edge_ray_cast

func Enter() -> void:
	enemy.animation_player.play("Fly")
	_dropping = false

func Exit() -> void:
	pass

func Process(_delta: float) -> EnemyState:
	return null

func Physics(_delta: float) -> EnemyState:
	if not _dropping:
		if not ground_ray.is_colliding():
			_dropping = true
			enemy.velocity.x = 0.0
			enemy.sprite.flip_h = PlayerManager.player.global_position.x > enemy.global_position.x
		else:
			enemy.velocity.x = enemy.stats.move_speed.value() * enemy.fly_direction()
			enemy.velocity.y = 0.0
	else:
		enemy.velocity.y = enemy.stats.move_speed.value()
		if enemy.is_on_floor():
			enemy.velocity = Vector2.ZERO
			return roost
	return null

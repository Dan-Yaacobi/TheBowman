class_name BirdbossFlyState extends EnemyState

const EGG = preload("uid://yvo6lok0c6eh")

var _direction: float = 1.0
var _was_colliding: bool = true

@onready var egg_timer: Timer = $EggTimer
@onready var transition: BirdbossTransitionState = $"../Transition"

func init() -> void:
	egg_timer.timeout.connect(_drop_egg)

func Enter() -> void:
	enemy.animation_player.play("Fly")
	egg_timer.wait_time = 2.0
	egg_timer.start()
	_was_colliding = true

func Exit() -> void:
	egg_timer.stop()

func Process(_delta: float) -> EnemyState:
	return null

func Physics(_delta: float) -> EnemyState:
	var is_colliding: bool = enemy.ground_edge_ray_cast.is_colliding()
	if _was_colliding and not is_colliding:
		_direction *= -1.0
	_was_colliding = is_colliding

	enemy.velocity.x = enemy.stats.move_speed.value() * _direction
	enemy.velocity.y = 0.0
	enemy.move_and_slide()

	if enemy.should_roost:
		return transition
	return null

func _spawn_bird(_position: Vector2) -> void:
	var bird_boss: BirdBoss = enemy as BirdBoss
	var bird: Enemy = PlayerManager.player.spawn_handler.spawn_from_zone(
		bird_boss.bird_entry.get_factory(),
		bird_boss.bird_entry.spawn_zone
	)
	if bird != null:
		bird_boss.active_birds.append(bird)
		bird.died.connect(func(_e: Enemy) -> void: bird_boss.active_birds.erase(bird))
		bird.global_position = _position
		enemy.get_parent().call_deferred("add_child", bird)
		
func _drop_egg() -> void:
	var egg: Egg = EGG.instantiate()
	egg.global_position = enemy.global_position
	EventBus.summon_effect.emit(egg)
	egg.cracked.connect(_spawn_bird)
	egg_timer.wait_time = 5.0

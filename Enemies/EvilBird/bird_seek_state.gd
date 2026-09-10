class_name BirdSeekState extends EnemyState

@onready var egg_attack: BirdEggAttackState = $"../EggAttack"

@export var height_above_player: float = 50
@export var height_threshold: float = 20
#what happens when we initialize this state
func init() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	enemy.animation_player.play("Move")
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	enemy.face_the_player()
	
	var target_y = PlayerManager.player.global_position.y - height_above_player
	var diff_y = enemy.global_position.y - target_y
	
	if abs(diff_y) <= height_threshold:
		return egg_attack
	
	enemy.velocity = enemy.calculate_direction_to_player(Vector2(0, -height_above_player)) * enemy.stats.move_speed.value()
	
	return null
	

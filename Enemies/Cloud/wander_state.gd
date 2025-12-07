class_name CloudWanderState extends EnemyState
@onready var wander_timer: Timer = $WanderTimer
@onready var seek: CloudSeekState = $"../Seek"
@onready var sprite: Sprite2D = $"../../Sprite2D"

var roam_left_max: float
var roam_right_max: float
var roam_bottom_max: float
var roam_top_max: float
var moving_up: bool = true
var moving_right: bool = true

var move_y_boost: int = 1
var move_x_boost: int = 1


func init() -> void:
	wander_timer.timeout.connect(start_seeking)
	pass

#what happens when the player enters this state
func Enter() -> void:
	var tween := create_tween()
	tween.tween_property(sprite.material, "shader_parameter/charge", 0.0, 0.5)
	sprite.frame = 0
	wander_timer.wait_time = randf_range(2,4)
	wander_timer.start()
	moving_up = [true,false].pick_random()
	moving_right = [true,false].pick_random()
	
#what happens when the player exits this state
func Exit() -> void:
	wander_timer.stop()
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	set_roam_boundries()
	roam_around(_delta)
	return null
	
func set_roam_boundries() -> void:
	roam_left_max = PlayerManager.player.global_position.x - randi_range(10,20)
	roam_right_max = PlayerManager.player.global_position.x + randi_range(10,20)
	roam_top_max = PlayerManager.player.global_position.y - randi_range(60,70)
	roam_bottom_max = PlayerManager.player.global_position.y - randi_range(50,55)
	pass

func roam_around(delta) -> void:
	
	## MOVING UP AND DOWN ##
	if moving_up:
		enemy.velocity.y -= enemy.stats.move_speed*delta*move_y_boost
		if enemy.global_position.y < roam_top_max:
			moving_up = false
			move_y_boost = 10
		else:
			move_y_boost -= 1
			move_y_boost = clampi(move_y_boost,1,10)
	else:
		enemy.velocity.y += enemy.stats.move_speed*delta*move_y_boost
		if enemy.global_position.y > roam_bottom_max:
			moving_up = true
			move_y_boost = 10
		else:
			move_y_boost -= 1
			move_y_boost = clampi(move_y_boost,1,10)
	
	## MOVING LEFT AND RIGHT ##
	if moving_right:
		enemy.velocity.x += enemy.stats.move_speed*delta*move_x_boost
		if enemy.global_position.x > roam_right_max:
			moving_right = false
			move_x_boost = 10
		else:
			move_x_boost -= 1
			move_x_boost = clampi(move_x_boost,1,10)
			
	else:
		enemy.velocity.x -= enemy.stats.move_speed*delta*move_x_boost
		if enemy.global_position.x < roam_left_max:
			moving_right = true
			move_x_boost = 10
		else:
			move_x_boost -= 1
			move_x_boost = clampi(move_x_boost,1,10)
			

func start_seeking() -> void:
	state_machine.ChangeState(seek)

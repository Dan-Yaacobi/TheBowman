class_name Boss2RoamState extends EnemyState

@onready var ability_timer: Timer = $"../../AbilityTimer"
@onready var pre_ability: Boss2PreAbility = $"../PreAbility"
@onready var shoot_timer: Timer = $"../../ShootTimer"

var roam_left_max: float
var roam_right_max: float
var roam_bottom_max: float
var roam_top_max: float
var moving_up: bool = true
var moving_right: bool = true

var move_y_boost: int = 1
var move_x_boost: int = 1

var shoot: bool = false
#what happens when we initialize this state

func init() -> void:
	ability_timer.timeout.connect(finished)
	shoot_timer.timeout.connect(enemy.shoot)

#what happens when the player enters this state
func Enter() -> void:
	shoot_timer.wait_time = randf_range(2,3)
	shoot_timer.start()
	ability_timer.wait_time = randi_range(5,10)
	ability_timer.start()
	
	shoot = false
	moving_up = [true,false].pick_random()
	moving_right = [true,false].pick_random()
	enemy.update_animation("Move")
	
	
#what happens when the player exits this state
func Exit() -> void:
	ability_timer.stop()
	shoot_timer.stop()
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	if shoot:
		return pre_ability
	set_roam_boundries()
	roam_around(_delta)
	return null

func finished() -> void:
	shoot = true

func set_roam_boundries() -> void:
	roam_left_max = enemy.player.global_position.x - randi_range(10,40)
	roam_right_max = enemy.player.global_position.x + randi_range(10,40)
	roam_top_max = enemy.player.global_position.y - randi_range(75,90)
	roam_bottom_max = enemy.player.global_position.y - randi_range(40,60)
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

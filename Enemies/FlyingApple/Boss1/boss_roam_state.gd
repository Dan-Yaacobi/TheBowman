class_name BossRoamState extends EnemyState

@onready var transition: BossTransitionState = $"../Transition"
@onready var shoot_timer: Timer = $"../../ShootTimer"
@onready var slam_timer: Timer = $"../../SlamTimer"
@onready var set_slam: BossSetSlamState = $"../SetSlam"
@onready var roof_detector: Area2D = $"../../RoofDetector"
@onready var collision_shape: CollisionShape2D = $"../../CollisionShape2D"
@onready var slam_particles: CPUParticles2D = $"../../SlamParticles"

var roam_left_max: float
var roam_right_max: float
var roam_bottom_max: float
var roam_top_max: float
var moving_up: bool = true
var moving_right: bool = true

var move_y_boost: int = 1
var move_x_boost: int = 1

var slam: bool

func init() -> void:
	slam_particles.emitting = false
	shoot_timer.timeout.connect(enemy.shoot)
	slam_timer.timeout.connect(go_to_slam)
	roof_detector.body_shape_entered.connect(dis_collision)
	pass

func Enter() -> void:
	enemy.set_collision_mask_value(5,true)
	shoot_timer.start()
	slam_timer.start()
	moving_up = [true,false].pick_random()
	moving_right = [true,false].pick_random()
	slam = false
	enemy.update_animation("Move")
	pass
	
func Exit() -> void:
	shoot_timer.stop()
	slam_timer.stop()
	pass
	
func Process(_delta: float) -> EnemyState:
	@warning_ignore("integer_division")
	if not enemy.half_hp_activation and enemy.current_hp <= enemy.stats.max_hp /2:
		enemy.half_hp_activation = true
		return transition
	return null
	
func Physics(_delta: float) -> EnemyState:
	if slam:
		return set_slam
	set_roam_boundries()
	roam_around(_delta)
	return null
	
func set_roam_boundries() -> void:
	roam_left_max = enemy.player.global_position.x - randi_range(10,40)
	roam_right_max = enemy.player.global_position.x + randi_range(10,40)
	roam_top_max = enemy.player.global_position.y - randi_range(70,80)
	roam_bottom_max = enemy.player.global_position.y - randi_range(40,60)
	pass

func roam_around(delta) -> void:
	
	## MOVING UP AND DOWN ##
	if moving_up:
		enemy.velocity.y -= enemy.stats.move_speed.value() * delta * move_y_boost
		if enemy.global_position.y < roam_top_max:
			moving_up = false
			move_y_boost = 10
		else:
			move_y_boost -= 1
			move_y_boost = clampi(move_y_boost,1,10)
	else:
		enemy.velocity.y += enemy.stats.move_speed.value() * delta * move_y_boost
		if enemy.global_position.y > roam_bottom_max:
			moving_up = true
			move_y_boost = 10
		else:
			move_y_boost -= 1
			move_y_boost = clampi(move_y_boost,1,10)
	
	## MOVING LEFT AND RIGHT ##
	if moving_right:
		enemy.velocity.x += enemy.stats.move_speed.value() * delta * move_x_boost
		if enemy.global_position.x > roam_right_max:
			moving_right = false
			move_x_boost = 10
		else:
			move_x_boost -= 1
			move_x_boost = clampi(move_x_boost,1,10)
			
	else:
		enemy.velocity.x -= enemy.stats.move_speed.value() * delta * move_x_boost
		if enemy.global_position.x < roam_left_max:
			moving_right = true
			move_x_boost = 10
		else:
			move_x_boost -= 1
			move_x_boost = clampi(move_x_boost,1,10)
			
func go_to_slam() -> void:
	slam = true

func dis_collision(_v1,_v2,_v3,_v4) -> void:
	enemy.set_collision_mask_value(5,false)
	

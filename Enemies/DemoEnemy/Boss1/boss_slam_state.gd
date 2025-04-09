class_name BossSlamState extends EnemyState

@onready var ground_detector: Area2D = $"../../GroundDetector"
@onready var roam: BossRoamState = $"../Roam"
@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $"../../VisibleOnScreenNotifier2D"
@onready var slam_particles: CPUParticles2D = $"../../SlamParticles"
@onready var slam_hit_particles: CPUParticles2D = $"../../SlamHitParticles"

var slam_speed_modifier: int = 8
var slam_done: bool = false

func init() -> void:
	ground_detector.body_shape_entered.connect(finished)
	visible_on_screen_notifier.screen_exited.connect(tp_back)
	pass

#what happens when the player enters this state
func Enter() -> void:
	enemy.update_animation("Slam")
	slam_particles.emitting = true
	slam_done = false
	enemy.velocity = Vector2.ZERO
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	slam_particles.emitting = false
	enemy.velocity = Vector2([1,-1].pick_random()*5,-enemy.stats.move_speed/4)
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	enemy.velocity.y += enemy.stats.move_speed * _delta * slam_speed_modifier
	if slam_done:
		return roam
	return null

func tp_back() -> void:
	slam_done = true
	
func finished(_v1,_v2,_v3,_v4) -> void:
	slam_done = true
	slam_hit_particles.emitting = true
	enemy.player.camera.apply_shake()
	
func hit(b) -> void:
	if b is Player:
		b.hit_player(enemy.stats.touch_damage)
	slam_done = true

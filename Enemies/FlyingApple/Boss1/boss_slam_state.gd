class_name BossSlamState extends EnemyState

@onready var ground_detector: Area2D = $"../../GroundDetector"
@onready var roam: BossRoamState = $"../Roam"
@onready var visible_on_screen_notifier: VisibleOnScreenNotifier2D = $"../../VisibleOnScreenNotifier2D"
@onready var slam_particles: CPUParticles2D = $"../../SlamParticles"

## Where the landing dust sits, local to the boss (the bottom of its ground detector).
const SLAM_EFFECT_OFFSET: Vector2 = Vector2(0, 5)

var slam_speed_modifier: int = 8
var slam_done: bool = false

func init() -> void:
	ground_detector.body_shape_entered.connect(finished)
	visible_on_screen_notifier.screen_exited.connect(tp_back)
	pass

#what happens when the player enters this state
func Enter() -> void:
	enemy.animation_player.play("Attack")
	slam_particles.emitting = true
	slam_done = false
	enemy.velocity = Vector2.ZERO
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	slam_particles.emitting = false
	enemy.velocity = Vector2([1,-1].pick_random()*5,-enemy.stats.move_speed.value()/4)
	enemy.animation_player.play("Move")
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	enemy.velocity.y += enemy.stats.move_speed.value() * _delta * slam_speed_modifier
	if slam_done:
		return roam
	return null

func tp_back() -> void:
	slam_done = true
	
## Ground contact only counts as a landing while this slam is running (the detector also
## touches islands the boss just flies past).
func finished(_v1,_v2,_v3,_v4) -> void:
	if state_machine.curr_state != self or slam_done:
		return
	slam_done = true
	EffectSprite.spawn(&"elite_apple_slam", enemy.to_global(SLAM_EFFECT_OFFSET))
	enemy.player.camera.apply_shake()
	
func hit(b) -> void:
	if b is Player:
		b.hit_player(enemy.stats.touch_damage)
	slam_done = true

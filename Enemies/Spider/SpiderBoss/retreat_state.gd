class_name SpiderBossRetreatState extends EnemyState

@onready var spider_summon_timer: Timer = $"../../SpiderSummonTimer"
@onready var web_shoot_timer: Timer = $"../../WebShootTimer"
@onready var slide_state: SpiderBossSlideState = $"../SlideState"

var retreat_hight: int = - 350
#what happens when we initialize this state
func init() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	enemy.hit_box.monitoring = false
	spider_summon_timer.stop()
	web_shoot_timer.stop()
	enemy.velocity = Vector2.ZERO

#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	enemy.velocity.y += -100*_delta
	if enemy.global_position.y < retreat_hight:
		return slide_state
	return null
	

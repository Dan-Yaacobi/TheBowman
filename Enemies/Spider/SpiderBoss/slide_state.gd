class_name SpiderBossSlideState extends EnemyState

const SPIDER_WEB = preload("res://Enemies/Spider/SpiderWeb.tscn")

@onready var fight_state: SpiderBossFightState = $"../FightState"
@onready var spider_summon_timer: Timer = $"../../SpiderSummonTimer"
@onready var web_shoot_timer: Timer = $"../../WebShootTimer"

var stop_height: int = -100
var web: SpiderWeb
#what happens when we initialize this state
func init() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	enemy.hit_box.monitoring = false
	if enemy.enraged:
		enemy.global_position.x = [-50,50].pick_random()
		enemy.scale *= 1.5
		enemy.sprite.modulate.s = 50
		
	spider_summon_timer.stop()
	web_shoot_timer.stop()
	
	web = SPIDER_WEB.instantiate()
	web.set_line(enemy.initial_pos,enemy.global_position)
	get_parent().get_parent().add_child(web)
	enemy.velocity.y = 75
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	web.set_line(enemy.initial_pos,enemy.global_position)
	if enemy.global_position.y > stop_height:
		return fight_state
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	
	return null
	

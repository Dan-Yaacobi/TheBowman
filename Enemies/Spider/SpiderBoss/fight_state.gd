class_name SpiderBossFightState extends EnemyState

@onready var retreat_state: SpiderBossRetreatState = $"../RetreatState"
@onready var spider_summon_timer: Timer = $"../../SpiderSummonTimer"
@onready var web_shoot_timer: Timer = $"../../WebShootTimer"

#what happens when we initialize this state
func init() -> void:
	spider_summon_timer.timeout.connect(enemy.summon_spider)
	web_shoot_timer.timeout.connect(enemy.shoot_web)
	pass

#what happens when the player enters this state
func Enter() -> void:
	enemy.hit_box.monitoring = true
	enemy.velocity = Vector2.ZERO
	set_initial_timer()
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	if enemy.enraged:
		enemy.sprite.modulate.s = 50
	if spider_summon_timer.is_stopped():
		spider_summon_timer.start()
	if web_shoot_timer.is_stopped():
		web_shoot_timer.start()
		
	if enemy.stats.hp <= enemy.max_hp/2 and not enemy.enraged:
		enemy.enraged = true
		return retreat_state
	return null
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	return null
	
func set_initial_timer() -> void:
	spider_summon_timer.wait_time = 1
	web_shoot_timer.wait_time = 1
	pass

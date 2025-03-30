class_name SpiderBoss extends Enemy

@onready var sprite: Sprite2D = $Sprite2D
@onready var spider_state_machine: EnemyStateMachine = $SpiderStateMachine
@onready var animation: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var spider_summon_timer: Timer = $SpiderSummonTimer
@onready var web_shoot_timer: Timer = $WebShootTimer
@onready var hit_box: Area2D = $HitBox

const SPIDER_WEB_PROJECTILE = preload("res://Enemies/Spider/SpiderBoss/SpiderWebProjectile.tscn")

var initial_pos: Vector2 = Vector2(0,-350)
var enraged: bool
var max_hp: int

func _ready() -> void:
	no_push_back = true
	hit_box.area_entered.connect(hit)
	enraged = false
	max_hp = stats.hp
	animation_player = animation
	spider_state_machine.Initialize(self)
	global_position = initial_pos
	scale *= 4
	#drops a little then stops
	#once stopped, shoots a web at the player every X seconds
	#also summons a spider every X seconds
	#at 50% hp it crawls back up, crawls down at a different position, 
	#becomes larger, slightly red and timers are faster
func _physics_process(delta: float) -> void:
	move_and_slide()
	
func summon_spider() -> void:
	var pg = get_parent()
	if pg is PlayGround:
		pg.summon_spider()
		spider_summon_timer.wait_time = randf_range(3.0,5.0)
		if enraged:
			spider_summon_timer.wait_time /= 2

func shoot_web() -> void:
	var web_projectile: SpiderWebProjectile = SPIDER_WEB_PROJECTILE.instantiate()
	web_projectile.direction = calculate_direction_to_player()
	web_projectile.global_position = global_position
	get_parent().add_child(web_projectile)
	web_shoot_timer.wait_time = randf_range(1.5,3.0)
	if enraged:
		web_shoot_timer.wait_time /= 2
		
	pass
	

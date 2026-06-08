class_name SpiderDroppingState extends EnemyState

const SPIDER_WEB = preload("res://Enemies/Spider/SpiderWeb.tscn")

@onready var dropping_animation: AnimationPlayer = $"../../DroppingSprite/DroppingAnimation"
@onready var ground_detector: Area2D = $"../../GroundDetector"
@onready var walking_state: SpiderWalkingState = $"../Walking"
@onready var dropping_sprite: Sprite2D = $"../../DroppingSprite"
@onready var walking_sprite: Sprite2D = $"../../WalkingSprite"

var web: SpiderWeb
var walking: bool = false
var initial_y: int
#what happens when we initialize this state

func init() -> void:
	pass

#what happens when the player enters this state
func Enter() -> void:
	enemy.sprite = dropping_sprite
	dropping_sprite.visible = true
	walking_sprite.visible = false
	enemy.stats.can_be_knockedback = false
	initial_y = enemy.global_position.y
	enemy.animation_player = dropping_animation
	enemy.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	walking = false
	ground_detector.body_shape_entered.connect(start_walking)

	web = SPIDER_WEB.instantiate()
	web.set_line(Vector2(enemy.initial_x,initial_y),enemy.global_position)
	get_parent().get_parent().add_child(web)
	enemy.update_animation("Move")
	pass
	
#what happens when the player exits this state
func Exit() -> void:
	web.queue_free()
	dropping_animation.stop()
	dropping_sprite.visible = false
	pass
	
#what happens during process update in this state
func Process(_delta: float) -> EnemyState:
	web.set_line(Vector2(enemy.initial_x,initial_y),enemy.global_position)
	if walking:
		return walking_state
	return null
	
#what happens during _physics_process update in this state
func Physics(_delta: float) -> EnemyState:
	return null
	
func start_walking(_v1,_v2,_v3,_v4) -> void:
	walking = true

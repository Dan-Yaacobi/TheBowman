class_name Spider extends Enemy

const SPIDER_WEB = preload("res://Enemies/Spider/SpiderWeb.tscn")

@export var initial_x: float
@export var gravity: int

@onready var visible_on_screen_notifier_2d: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
@onready var enemy_state_machine: Node2D = $EnemyStateMachine
@onready var ground_detector: Area2D = $GroundDetector

var web: SpiderWeb

func extra_ready_functions() -> void:
	#visible_on_screen_notifier_2d.screen_exited.connect(enemy_died)
	enemy_state_machine.Initialize(self)
	initial_x = PlayerManager.player.global_position.x
	hit_box.area_entered.connect(hit)
	hurt_box.body_entered.connect(player_hit)
	
func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	move_and_slide()
	
func apply_gravity(delta) -> void:
	if is_on_floor():
		velocity.y = 0
	else:
		velocity.y += gravity * delta

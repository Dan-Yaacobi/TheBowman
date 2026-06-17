class_name BirdBoss extends Enemy

const ROOST_THRESHOLDS: Array[float] = [0.75, 0.50, 0.25]

var should_roost: bool = false
var _remaining_thresholds: Array[float] = []
var active_birds: Array[Enemy] = []

@onready var ground_edge_ray_cast: RayCast2D = $GroundEdgeRayCast
@onready var fly: BirdbossFlyState = $EnemyStateMachine/Fly
@onready var wind: Wind = $Wind

@export var bird_entry: EnemyEntry

func extra_ready_functions() -> void:
	animation_player = $Sprite2D/AnimationPlayer
	_remaining_thresholds = ROOST_THRESHOLDS.duplicate()
	state_machine.Initialize(self)

func fly_direction() -> float:
	return fly._direction

func call_birds_to_roost() -> void:
	for bird in active_birds:
		if is_instance_valid(bird) and bird is EvilBird:
			bird.fly_to_roost(global_position)

func extra_hit_functions(_hurt_box: HurtBox) -> void:
	_check_roost_threshold()

func _physics_process(_delta: float) -> void:
	move_and_slide()
	
func _check_roost_threshold() -> void:
	if _remaining_thresholds.is_empty():
		return
	var hp_percent: float = float(current_hp) / float(stats.max_hp)
	if hp_percent <= _remaining_thresholds[0]:
		_remaining_thresholds.pop_front()
		should_roost = true


func _on_roost_detector_body_entered(body: Node2D) -> void:
	if body is EvilBird:
		active_birds.erase(body)
		heal(roundi(body.stats.max_hp / 10))
		body.queue_free()

class_name BirdBoss extends Boss

const ROOST_THRESHOLDS: Array[float] = [0.75, 0.50, 0.25]

var should_roost: bool = false
var _remaining_thresholds: Array[float] = []
var active_birds: Array[Enemy] = []

@onready var ground_edge_ray_cast: RayCast2D = $GroundEdgeRayCast
@onready var fly: BirdbossFlyState = $EnemyStateMachine/Fly
@onready var wind: Wind = $Wind
const HEAL_PARTICLES = preload("uid://dsjlyhals6f2v")

@export var bird_entry: EnemyEntry

func extra_ready_functions() -> void:
	animation_player = $Sprite2D/AnimationPlayer
	_remaining_thresholds = ROOST_THRESHOLDS.duplicate()
	state_machine.Initialize(self)
	if boss_health_bar:
		boss_health_bar.init_health(stats.max_hp)
		
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
	if velocity.x != 0:
		sprite.flip_h = velocity.x > 0
		
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
		heal(roundi(body.stats.max_hp))
		var heal_particles: CPUParticles2D = HEAL_PARTICLES.instantiate()
		heal_particles.global_position = body.global_position
		heal_particles.emitting = true
		get_tree().create_timer(heal_particles.lifetime).timeout.connect(heal_particles.queue_free)
		EventBus.summon_effect.emit(heal_particles)
		body.queue_free()

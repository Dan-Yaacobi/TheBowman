class_name BirdbossRoostState extends EnemyState

@onready var whirlwind_timer: Timer = $WhirlwindTimer
@onready var roost_timer: Timer = $RoostTimer
@onready var roost_detector: Area2D = $"../../RoostDetector"

const GROW_SPEED: float = 200.0
var wind_active: bool = false

func init() -> void:
	whirlwind_timer.timeout.connect(_trigger_whirlwind)
	roost_timer.timeout.connect(_end_roost)

func Enter() -> void:
	roost_detector.monitoring = true
	enemy.animation_player.play("Land")
	enemy.velocity = Vector2.ZERO
	enemy.set_damage_taken_multiplier(0.5,Stat.buff_type.ADDITIVE)
	(enemy as BirdBoss).call_birds_to_roost()
	whirlwind_timer.start()
	roost_timer.start()

func Exit() -> void:
	roost_detector.monitoring = false
	enemy.wind.disable()
	roost_timer.stop()
	enemy.remove_damage_taken_multiplier(0.5,Stat.buff_type.ADDITIVE)
	(enemy as BirdBoss).should_roost = false

func Process(_delta: float) -> EnemyState:
	if wind_active:
		enemy.wind.grow(GROW_SPEED * _delta)
	return null

func Physics(_delta: float) -> EnemyState:
	return null

func _trigger_whirlwind() -> void:
	enemy.animation_player.play("Whirlwind")
	enemy.wind.face_player()
	enemy.wind.enable(Vector2(enemy.wind.scale.x, 0))
	wind_active = true
	enemy.wind.knockback_force = 7500
	whirlwind_timer.stop()
	
func _end_roost() -> void:
	state_machine.ChangeState(state_machine.states[0])

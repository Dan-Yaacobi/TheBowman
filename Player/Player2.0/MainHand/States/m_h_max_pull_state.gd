class_name MaxPullMainHandState extends MainHandState

@onready var idle: IdleMainHandState = $"../Idle"

@onready var perfect_aim_particles: CPUParticles2D = $"../../PerfectAimParticles"
@onready var perfect_shot_window: Timer = $PerfectShotWindow

var hold_time: float = 0
var tired: bool = false
## Seconds the overcharge fill takes (same as the first draw at the current pull speed).
var overcharge_duration: float = 1.0
signal max_pull
signal overcharged

func init() -> void:
	perfect_shot_window.timeout.connect(getting_tired)

func Enter() -> void:
	tired = false
	perfect_shot_window.wait_time = PlayerManager.player.stats.perfect_shot_window.value()
	#perfect_aim_particles.rotation = entity.rotation
	#perfect_aim_particles.emitting = true
	hold_time = 0
	entity.overcharge = 0.0
	overcharge_duration = entity.animation_player.get_animation("Pull").length / maxf(PlayerManager.player.get_pull_speed(), 0.01)
	max_pull.emit()
	entity.animation_player.play("Max Pull")
	# With overcharge, tiredness waits until the second fill is full.
	if not entity.overcharge_enabled:
		perfect_shot_window.start()

func Exit() -> void:
	hold_time = 0
	perfect_shot_window.stop()
	entity.overcharge = 0.0

func Process(_delta: float) -> MainHandState:
	entity.arrow_setup()

	if entity.overcharge_enabled and not tired and entity.overcharge < 1.0:
		entity.overcharge = minf(entity.overcharge + _delta / overcharge_duration, 1.0)
		if entity.overcharge >= 1.0:
			overcharged.emit()
			perfect_shot_window.start()

	if tired:
		hold_time += _delta * 3
		# Drains backwards: the overcharge empties first, then the draw itself.
		if entity.overcharge > 0.0:
			entity.overcharge = maxf(entity.overcharge - _delta / 2, 0.0)
		else:
			entity.shot_power = max(entity.shot_power - _delta/2, entity.min_shot_power)

	return null

func release() -> void:
	state_machine.ChangeState(idle)

func Physics(_delta: float) -> MainHandState:
	return null

#what happens during input events in this state
func HandleInput(_event: InputEvent) -> MainHandState:
	return null

func getting_tired() -> void:
	tired = true

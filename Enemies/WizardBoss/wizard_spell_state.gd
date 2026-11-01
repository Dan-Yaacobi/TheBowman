class_name WizardSpellState extends EnemyState

@export var idle_state: EnemyState
@export var cast_animation: String = "Cast"
@export var cast_duration: float = 1.0
## Off = cast right where he stands, straight from idle, with no teleport first
@export var teleport_before: bool = true
## How bright his hands glow while casting this spell (0 = no glow)
@export var cast_glow: float = 1.0

var wizard: WizardBoss
var _elapsed: float = 0.0

func init() -> void:
	wizard = enemy as WizardBoss

func Enter() -> void:
	_elapsed = 0.0
	wizard.update_animation(cast_animation)
	wizard.set_cast_glow(cast_glow)
	on_cast_start()

func Exit() -> void:
	wizard.set_cast_glow(0.0)

func Physics(delta: float) -> EnemyState:
	_elapsed += delta
	cast_process(delta)
	if is_finished():
		return idle_state
	return null

## False skips this spell's turn in the rotation (e.g. its effect is still active)
func can_cast() -> bool:
	return true

# Override in spells
func on_cast_start() -> void:
	pass

func cast_process(_delta: float) -> void:
	pass

func is_finished() -> bool:
	return _elapsed >= cast_duration

# Where the wizard teleports before this spell; override per spell
func pick_point(points: Array[Marker2D], current: Marker2D) -> Marker2D:
	return random_point(points, current)

static func random_point(points: Array[Marker2D], current: Marker2D) -> Marker2D:
	var options: Array[Marker2D] = []
	for p: Marker2D in points:
		if p != current:
			options.append(p)
	if options.is_empty():
		return current
	return options.pick_random()

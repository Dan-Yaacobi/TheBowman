class_name WizardSpellState extends EnemyState

@export var idle_state: EnemyState
@export var cast_animation: String = "Cast"
@export var cast_duration: float = 1.0

var wizard: WizardBoss
var _elapsed: float = 0.0

func init() -> void:
	wizard = enemy as WizardBoss

func Enter() -> void:
	_elapsed = 0.0
	wizard.update_animation(cast_animation)
	on_cast_start()

func Physics(delta: float) -> EnemyState:
	_elapsed += delta
	cast_process(delta)
	if is_finished():
		return idle_state
	return null

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

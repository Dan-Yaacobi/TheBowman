class_name WizardIdleState extends EnemyState

@export var idle_duration: float = 1.5
@export var idle_animation: String = "Idle"
@onready var teleport: WizardTeleportState = $"../Teleport"

var _elapsed: float = 0.0

func Enter() -> void:
	_elapsed = 0.0
	enemy.update_animation(idle_animation)
	
func Physics(delta: float) -> EnemyState:
	_elapsed += delta
	if _elapsed >= idle_duration:
		return teleport
	return null

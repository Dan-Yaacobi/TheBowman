class_name PineDormantState extends EnemyState
## Looks like a plain pine. Hardened: every hit deals 1 damage, no debuffs or stuns.
## Wakes when the player comes within wake_range.

@export var wake_state: EnemyState

var pine: PineTree


func init() -> void:
	pine = enemy as PineTree


func Enter() -> void:
	pine.hardened = true
	pine.set_swipe_active(false)
	pine.animation_player.play(&"Dormant")


func Exit() -> void:
	pine.hardened = false


func Physics(_delta: float) -> EnemyState:
	if PlayerManager.player and pine.calculate_distance_to_player() <= pine.pine_data.wake_range:
		return wake_state
	return null

class_name RootedDormantState extends EnemyState
## Asleep on its island. Hardened: every hit deals 1 damage, no debuffs or stuns.
## Wakes when the player comes within wake_range.

@export var wake_state: EnemyState
@export var animation_name: StringName = &"Dormant"

var rooted: RootedEnemy


func init() -> void:
	rooted = enemy as RootedEnemy


func Enter() -> void:
	rooted.hardened = true
	rooted.on_dormant_changed(true)
	if rooted.animation_player and rooted.animation_player.has_animation(animation_name):
		rooted.animation_player.play(animation_name)


func Exit() -> void:
	rooted.hardened = false
	rooted.reset_sleep_timer()
	rooted.on_dormant_changed(false)


func Physics(_delta: float) -> EnemyState:
	if PlayerManager.player and rooted.calculate_distance_to_player() <= rooted.rooted_data.wake_range:
		return wake_state
	return null

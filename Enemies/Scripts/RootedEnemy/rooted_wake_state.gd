class_name RootedWakeState extends EnemyState
## Plays the wake-up animation (the telegraph that it's about to attack), then moves on once it
## has finished. Hits don't interrupt it.

@export var next_state: EnemyState
@export var animation_name: StringName = &"Wake"

var rooted: RootedEnemy


func init() -> void:
	rooted = enemy as RootedEnemy


func Enter() -> void:
	rooted.face_the_player()
	rooted.animation_player.play(animation_name)


func blocks_flinch() -> bool:
	return true


func Physics(_delta: float) -> EnemyState:
	if not rooted.animation_player.is_playing() or rooted.animation_player.current_animation != animation_name:
		return next_state
	return null

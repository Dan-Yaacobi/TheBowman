class_name RockGolemWakeState extends EnemyState
## Plays the rock-to-golem transformation, then hands over to the awake state.

@export var next_state: EnemyState
@export var animation_name: StringName = &"Wake"

var golem: RockGolem
var _finished: bool = false


func init() -> void:
	golem = enemy as RockGolem
	golem.animation_player.animation_finished.connect(_on_animation_player_animation_finished)


func Enter() -> void:
	_finished = false
	golem.set_dormant(false)
	golem.move_x = 0.0
	golem.face_the_player()
	golem.update_animation(animation_name)


func Physics(_delta: float) -> EnemyState:
	if _finished:
		return next_state
	return null


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == animation_name:
		_finished = true

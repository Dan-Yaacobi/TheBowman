class_name RockGolemWakeState extends EnemyState
## Plays the rock-to-golem transformation, then hands over to the awake state.

@export var next_state: EnemyState
@export var animation_name: StringName = &"Wake"
## Growth runs while the rock unfolds (the Wake frames where it stands up)
@export var grow_delay: float = 0.3
@export var grow_duration: float = 0.8

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
	var grow: Tween = golem.create_tween()
	grow.tween_interval(grow_delay)
	grow.tween_property(golem, "scale", Vector2.ONE * golem.stats.size * golem.golem_data.awake_size, grow_duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func Physics(_delta: float) -> EnemyState:
	if _finished:
		return next_state
	return null


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == animation_name:
		_finished = true

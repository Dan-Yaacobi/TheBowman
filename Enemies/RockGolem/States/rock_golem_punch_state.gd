class_name RockGolemPunchState extends EnemyState
## Plants its feet and punches. The Punch animation switches the fist's hurtbox on
## only during the impact frames, so the wind-up is a fair warning.

@export var idle_state: EnemyState
@export var animation_name: StringName = &"Punch"

var golem: RockGolem
var _finished: bool = false


func init() -> void:
	golem = enemy as RockGolem
	golem.animation_player.animation_finished.connect(_on_animation_player_animation_finished)


func Enter() -> void:
	_finished = false
	golem.move_x = 0.0
	golem.face_the_player()
	golem.update_animation(animation_name)


func Exit() -> void:
	# In case the punch was cut short (stun, capture) while the fist was live
	golem.punch_hurt_box.set_deferred("monitoring", false)
	golem.punch_cooldown_left = golem.golem_data.punch_cooldown


func Physics(_delta: float) -> EnemyState:
	if _finished:
		return idle_state
	return null


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == animation_name:
		_finished = true

class_name RockGolemThrowState extends EnemyState
## Pulls a boulder out of the ground and hurls it at the player. The real boulder is
## released on the frame where the drawn one has left its hands.

@export var idle_state: EnemyState
@export var animation_name: StringName = &"Throw"
## Sprite sheet frame where the boulder has left its hands (Throw row, 11th frame)
@export var release_frame: int = 62

var golem: RockGolem
var _released: bool = false
var _finished: bool = false


func init() -> void:
	golem = enemy as RockGolem
	golem.animation_player.animation_finished.connect(_on_animation_player_animation_finished)


func Enter() -> void:
	_released = false
	_finished = false
	golem.move_x = 0.0
	golem.face_the_player()
	golem.update_animation(animation_name)


func Physics(_delta: float) -> EnemyState:
	if not _released and golem.sprite.frame >= release_frame:
		_released = true
		golem.throw_boulder()
	if _finished:
		return idle_state
	return null


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == animation_name:
		_finished = true

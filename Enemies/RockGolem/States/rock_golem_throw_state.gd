class_name RockGolemThrowState extends EnemyState
## Pulls a boulder out of the ground and hurls it at the player. A real boulder sits in
## its hands from the start (the animation shows and moves it) and is let go on release_frame.

@export var idle_state: EnemyState
@export var animation_name: StringName = &"Throw"
## Sprite sheet frame where it lets go (Throw row, 10th frame)
@export var release_frame: int = 61

var golem: RockGolem
var _released: bool = false
var _boulder: Boulder
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
	_boulder = golem.pick_up_boulder()


func Exit() -> void:
	# Cut short (stun, death): the boulder never leaves its hands
	if not _released and is_instance_valid(_boulder):
		_boulder.queue_free()
	_boulder = null


func Physics(_delta: float) -> EnemyState:
	if not _released and golem.sprite.frame >= release_frame:
		_released = true
		golem.throw_boulder(_boulder)
	if _finished:
		return idle_state
	return null


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == animation_name:
		_finished = true

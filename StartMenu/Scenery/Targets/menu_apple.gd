class_name MenuApple extends MenuTarget
## A winged apple hovering over the islands. When shot it flashes, gets knocked
## back along the arrow's path, spins and flaps frantically, then flutters home.

@export var hover_size: Vector2 = Vector2(3.0, 2.0)
@export var hover_speed: float = 1.0
@export var knockback: float = 16.0
@export var recover_time: float = 1.4
## Flap speed multiplier right after a hit.
@export var panic_flap: float = 3.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _rest: Vector2
var _phase: float = 0.0
var _time: float = 0.0
var _knock: Vector2 = Vector2.ZERO
var _knock_tween: Tween

func _ready() -> void:
	_rest = position
	_phase = randf() * TAU
	animation_player.play(&"flap")
	animation_player.seek(randf() * animation_player.current_animation_length)

func _process(delta: float) -> void:
	_time += delta
	var hover: Vector2 = Vector2(sin(_time * hover_speed * 0.7 + _phase), sin(_time * hover_speed * 1.9 + _phase)) * hover_size
	position = _rest + hover + _knock

func react(arrow: MenuArrow, _local_point: Vector2) -> void:
	var direction: Vector2 = Vector2.RIGHT.rotated(arrow.rotation)
	arrow.reparent(get_parent())
	arrow.drop(direction * 10.0 + Vector2(0.0, -6.0), 60.0)
	play_hit_sound()
	flash()
	if _knock_tween and _knock_tween.is_valid():
		_knock_tween.kill()
	_knock_tween = create_tween().set_parallel()
	_knock_tween.tween_property(self, "_knock", direction * knockback, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_knock_tween.tween_property(self, "rotation", signf(direction.x + 0.01) * TAU * 2.0, 0.6).from(0.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_knock_tween.tween_property(animation_player, "speed_scale", 1.0, recover_time).from(panic_flap)
	_knock_tween.chain().tween_property(self, "_knock", Vector2.ZERO, recover_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_knock_tween.parallel().tween_property(self, "rotation", 0.0, 0.01)

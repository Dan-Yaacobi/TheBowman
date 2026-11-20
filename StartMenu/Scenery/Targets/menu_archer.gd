class_name MenuArcher extends MenuTarget
## The archer on the near island, watching the sunset with his cloak stirring in
## the wind. When shot he flinches, glances back over his shoulder at whoever
## did it, then turns back to the view. The arrow glances off.

@export var flinch_squash: Vector2 = Vector2(1.12, 0.86)

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var _flinch_tween: Tween

func _ready() -> void:
	animation_player.play(&"sway")
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)

func react(arrow: MenuArrow, _local_point: Vector2) -> void:
	arrow.reparent(get_parent())
	arrow.drop(Vector2(-20.0, -14.0), 70.0)
	play_hit_sound()
	flash()
	animation_player.play(&"look_back")
	if _flinch_tween and _flinch_tween.is_valid():
		_flinch_tween.kill()
	# Squash from the feet (the sprite's origin), then spring back.
	_flinch_tween = create_tween()
	_flinch_tween.tween_property(self, "scale", flinch_squash, 0.05)
	_flinch_tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _on_animation_player_animation_finished(animation: StringName) -> void:
	if animation == &"look_back":
		animation_player.play(&"sway")

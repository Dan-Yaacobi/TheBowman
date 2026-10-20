extends Node2D

@export var draw_animation: StringName = &"draw"

@onready var body: AnimatedSprite2D = $Body
@onready var main_hand: AnimatedSprite2D = $MainHand
@onready var off_hand: AnimatedSprite2D = $OffHand

var _sprites: Array[AnimatedSprite2D] = []
var _hands: Array[AnimatedSprite2D] = []
var _was_holding: bool = false


func _ready() -> void:
	_sprites = [body, main_hand, off_hand]
	_hands = [main_hand, off_hand]


func _process(_delta: float) -> void:
	var holding: bool = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

	if holding and not _was_holding:
		_start_draw()
	elif not holding and _was_holding:
		_end_draw()

	if holding:
		_face_mouse()
		_aim()
		_hold_last_frame()

	_was_holding = holding


func _face_mouse() -> void:
	var facing_left: bool = get_global_mouse_position().x < global_position.x
	scale.x = -1.0 if facing_left else 1.0


func _aim() -> void:
	# to_local accounts for the flip, so the hands always aim in "facing right" space.
	var local_target: Vector2 = to_local(get_global_mouse_position())
	for hand: AnimatedSprite2D in _hands:
		hand.rotation = (local_target - hand.position).angle()


func _start_draw() -> void:
	for sprite: AnimatedSprite2D in _sprites:
		if sprite.sprite_frames.has_animation(draw_animation):
			sprite.play(draw_animation)
			sprite.set_frame_and_progress(0, 0.0)


func _end_draw() -> void:
	for sprite: AnimatedSprite2D in _sprites:
		sprite.stop()
		sprite.set_frame_and_progress(0, 0.0)
	for hand: AnimatedSprite2D in _hands:
		hand.rotation = 0.0


func _hold_last_frame() -> void:
	for sprite: AnimatedSprite2D in _sprites:
		if sprite.animation != draw_animation:
			continue
		var last_frame: int = sprite.sprite_frames.get_frame_count(draw_animation) - 1
		if sprite.frame >= last_frame:
			sprite.pause()

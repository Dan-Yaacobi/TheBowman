extends Camera2D

@onready var player: Player = $".."
@export var random_strength: float = 30.0
@export var shake_fade: float = 5.0
@export var move_speed_variant: float = 8.0
@export var base_zoom: Vector2
var rng = RandomNumberGenerator.new()
var shake_strength: float = 0.0

var moving_camera: bool = false
var target_move: Vector2
var _zoom_tween: Tween

@export_group("Juice")
## How far the view leans toward the cursor, in px, and how much of the cursor distance it takes.
@export var aim_lead_max: float = 18.0
@export var aim_lead_share: float = 0.08
## How fast a zoom punch settles back (per second).
@export var punch_recovery: float = 9.0
@export_group("")

## Zoom the tweens move between (base or zoomed-out); punches multiply on top of it.
var _zoom_level: Vector2
var _punch: float = 0.0

func _ready() -> void:
	player.took_hit.connect(apply_shake)
	player.critical_hit.connect(apply_shake)
	EventBus.change_camera_focus.connect(change_focus)
	EventBus.reset_camera_focus.connect(reset_focus)
	EventBus.camera_shake.connect(apply_shake)
	EventBus.camera_punch.connect(punch)
	_zoom_level = base_zoom
	zoom = base_zoom
	pass
	
func _physics_process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0 , shake_fade * delta)
		offset = random_offset()
	if moving_camera:
		move_the_camera(target_move, delta)
	else:
		move_the_camera(player.global_position + _aim_lead(), delta)
	_punch = move_toward(_punch, 0.0, _punch * punch_recovery * delta + 0.0005)
	zoom = _zoom_level * (1.0 + _punch)

## A quick zoom-in kick on big moments (crits, boss hits, devours). 0.05 = 5% closer.
func punch(strength: float = 0.05) -> void:
	_punch = maxf(_punch, strength)

## The view leans a little toward where the archer is aiming.
func _aim_lead() -> Vector2:
	var to_mouse: Vector2 = get_global_mouse_position() - player.global_position
	return to_mouse.normalized() * minf(to_mouse.length() * aim_lead_share, aim_lead_max)

func apply_shake(_strength: float = random_strength, _fade: float = 10.0) -> void:
	shake_strength = _strength
	shake_fade = _fade
	
func random_offset() -> Vector2:
	return Vector2(rng.randf_range(-shake_strength,shake_strength),rng.randf_range(-shake_strength,shake_strength))

func move_the_camera(target: Vector2, delta: float) -> void:
	global_position = lerp(global_position,target,move_speed_variant * delta)
	pass
	
func change_focus(target: Vector2) -> void:
	moving_camera = true
	target_move = target
	pass

func reset_focus() -> void:
	moving_camera = false
	pass
	
#func _unhandled_input(event: InputEvent) -> void:
	#if event.is_action_pressed("zoom in"):
		#zoom += Vector2(0.1,0.1)
	#if event.is_action_pressed("zoom out"):
		#zoom -= Vector2(0.1,0.1)
	#pass

func zoom_out() -> void:
	_tween_zoom(base_zoom - Vector2(1, 1))

func zoom_in() -> void:
	_tween_zoom(base_zoom)

func _tween_zoom(target: Vector2) -> void:
	if _zoom_tween:
		_zoom_tween.kill()
	_zoom_tween = create_tween()
	_zoom_tween.tween_property(self, "_zoom_level", target, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

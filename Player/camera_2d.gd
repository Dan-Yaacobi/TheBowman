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

func _ready() -> void:
	player.took_hit.connect(apply_shake)
	player.critical_hit.connect(apply_shake)
	EventBus.change_camera_focus.connect(change_focus)
	EventBus.reset_camera_focus.connect(reset_focus)
	EventBus.camera_shake.connect(apply_shake)
	zoom = base_zoom
	pass
	
func _physics_process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerpf(shake_strength, 0 , shake_fade * delta)
		offset = random_offset()
	if moving_camera:
		move_the_camera(target_move, delta)
	else:
		move_the_camera(player.global_position, delta)

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
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom in"):
		zoom += Vector2(0.1,0.1)
	if event.is_action_pressed("zoom out"):
		zoom -= Vector2(0.1,0.1)
	pass
	
func zoom_out() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "zoom", base_zoom - Vector2(1,1), 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

func zoom_in() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(self, "zoom", base_zoom, 1.5).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)

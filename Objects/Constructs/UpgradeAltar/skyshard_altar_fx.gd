class_name SkyshardAltarFX
extends Node2D

@export var crystal: Node2D
@export var detect_area: Area2D
## Every ShaderMaterial with an "activation" uniform (pool, both helix rects, halo, runes).
@export var effect_materials: Array[ShaderMaterial] = []
@export var particles: Array[GPUParticles2D] = []

@export_group("Crystal")
@export var rest_offset: Vector2 = Vector2(0.0, 4.0)
@export var hover_offset: Vector2 = Vector2(0.0, -10.0)
@export var bob_amplitude: float = 1.5
@export var bob_speed: float = 2.0
@export var dormant_modulate: Color = Color(0.45, 0.45, 0.6, 1.0)
@export var snap_to_pixels: bool = true

@export_group("Timing")
@export var wake_duration: float = 0.8
@export var sleep_duration: float = 1.4

var activation: float = 0.0
var _crystal_base: Vector2
var _bob_time: float = 0.0
var _tween: Tween

func _ready() -> void:
	_crystal_base = crystal.position
	detect_area.body_entered.connect(_on_body_entered)
	detect_area.body_exited.connect(_on_body_exited)
	for p: GPUParticles2D in particles:
		p.emitting = false
	_apply_activation(0.0)

func _process(delta: float) -> void:
	_bob_time += delta
	var lift: Vector2 = rest_offset.lerp(hover_offset, ease(activation, -2.0))
	var bob: float = sin(_bob_time * bob_speed) * bob_amplitude * activation
	var target_pos: Vector2 = _crystal_base + lift + Vector2(0.0, bob)
	crystal.position = target_pos.round() if snap_to_pixels else target_pos

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_transition_to(1.0, wake_duration)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group(&"player"):
		_transition_to(0.0, sleep_duration)

func _transition_to(target: float, duration: float) -> void:
	if _tween:
		_tween.kill()
	for p: GPUParticles2D in particles:
		p.emitting = target > 0.5
	_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.tween_method(_apply_activation, activation, target, duration)

func _apply_activation(value: float) -> void:
	activation = value
	for mat: ShaderMaterial in effect_materials:
		mat.set_shader_parameter(&"activation", value)
	crystal.modulate = dormant_modulate.lerp(Color.WHITE, value)

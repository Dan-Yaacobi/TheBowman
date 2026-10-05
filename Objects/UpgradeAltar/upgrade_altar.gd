class_name UpgradeAltar extends NPC

@export var crystal: Node2D
## Nodes whose shader has an "activation" uniform (pool, both helix rects, halo, base sprite).
@export var effect_nodes: Array[CanvasItem] = []
@export var particles: Array[CPUParticles2D] = []

@export_group("Crystal")
@export var rest_offset: Vector2 = Vector2(0.0, 4.0)
@export var hover_offset: Vector2 = Vector2(0.0, -10.0)
@export var bob_amplitude: float = 2.0
@export var bob_speed: float = 2.0
@export var dormant_modulate: Color = Color(0.45, 0.45, 0.6, 1.0)
@export var snap_to_pixels: bool = true

@export_group("Timing")
@export var wake_duration: float = 0.8
@export var sleep_duration: float = 1.4

var activation: float = 0.0
var _crystal_base: Vector2
var _bob_time: float = 0.0
var _fx_tween: Tween

func extra_ready_functions() -> void:
	_crystal_base = crystal.position
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)
	for p: CPUParticles2D in particles:
		p.emitting = false
	_apply_activation(0.0)

func extra_process_function(delta: float) -> void:
	_bob_time += delta
	var lift: Vector2 = rest_offset.lerp(hover_offset, ease(activation, -2.0))
	var bob: float = sin(_bob_time * bob_speed) * bob_amplitude * activation
	var target_pos: Vector2 = _crystal_base + lift + Vector2(0.0, bob)
	crystal.position = target_pos.round() if snap_to_pixels else target_pos

func _on_body_entered(body: Node2D) -> void:
	if body == PlayerManager.player:
		_transition_to(1.0, wake_duration)

func _on_body_exited(body: Node2D) -> void:
	if body == PlayerManager.player:
		_transition_to(0.0, sleep_duration)

func _transition_to(target: float, duration: float) -> void:
	if _fx_tween:
		_fx_tween.kill()
	for p: CPUParticles2D in particles:
		p.emitting = target > 0.5
	_fx_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fx_tween.tween_method(_apply_activation, activation, target, duration)

func _apply_activation(value: float) -> void:
	activation = value
	for node: CanvasItem in effect_nodes:
		var mat: ShaderMaterial = node.material as ShaderMaterial
		if mat:
			mat.set_shader_parameter(&"activation", value)
	crystal.modulate = dormant_modulate.lerp(Color.WHITE, value)

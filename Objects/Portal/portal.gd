@tool
class_name Portal extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D
@onready var proximity_area: Area2D = $ProximityArea

@export var color: Color = Color.WHITE:
	set(value):
		color = value
		if Engine.is_editor_hint():
			call_deferred("_update_color")
		else:
			_update_color()

@export var destination: GameWorlds.worlds = GameWorlds.worlds.Main_Menu
@export var is_rift_portal: bool = false

@export var flip_h: bool = false:
	set(value):
		flip_h = value
		if Engine.is_editor_hint():
			call_deferred("_update_flip")
		else:
			_update_flip()

@export_group("Effects")
## Particles that only run while the player is near (e.g. the inward pull).
@export var near_particles: Array[CPUParticles2D] = []
@export var idle_speed: float = 0.5
@export var near_speed: float = 1.4
@export var wake_duration: float = 0.3
@export var sleep_duration: float = 1.0

var _proximity: float = 0.0
var _phase: float = 0.0
var _fx_tween: Tween

func _ready() -> void:
	_update_flip()
	_update_color()
	if Engine.is_editor_hint():
		return
	proximity_area.body_entered.connect(_on_proximity_entered)
	proximity_area.body_exited.connect(_on_proximity_exited)
	for p: CPUParticles2D in near_particles:
		p.emitting = false
	_apply_proximity(0.0)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_phase = fmod(_phase + delta * lerpf(idle_speed, near_speed, _proximity), 1000.0)
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter(&"phase", _phase)

func disable() -> void:
	area_2d.monitoring = false
	proximity_area.monitoring = false
	modulate.a = 0.75
	_set_awake(false)

func enable() -> void:
	area_2d.monitoring = true
	proximity_area.monitoring = true
	modulate.a = 1

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		body.current_portal = self

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body is Player:
		body.current_portal = null

func _on_proximity_entered(body: Node2D) -> void:
	if body is Player:
		_set_awake(true)

func _on_proximity_exited(body: Node2D) -> void:
	if body is Player:
		_set_awake(false)

func enter() -> void:
	if is_rift_portal:
		EventBus.entered_rift_portal.emit()
	elif destination is GameWorlds.worlds:
		EventBus.changed_scene.emit(destination)

func _set_awake(awake: bool) -> void:
	if _fx_tween:
		_fx_tween.kill()
	for p: CPUParticles2D in near_particles:
		p.emitting = awake
	var target: float = 1.0 if awake else 0.0
	var duration: float = wake_duration if awake else sleep_duration
	_fx_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fx_tween.tween_method(_apply_proximity, _proximity, target, duration)

func _apply_proximity(value: float) -> void:
	_proximity = value
	var mat: ShaderMaterial = sprite.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter(&"proximity", value)

func _update_flip() -> void:
	if sprite:
		sprite.flip_h = flip_h

func _update_color() -> void:
	if sprite:
		sprite.modulate = color

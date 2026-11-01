class_name AreaWarning extends Node2D
## Shows where an area attack will land: a circle whose fill grows from the centre
## and touches the rim when time runs out. Call start(radius, duration); `finished` fires at the end.
## Recolour it through the Area's shader material.

signal finished

## Rim pulses per second at the start; it speeds up toward the end
@export var pulse_speed: float = 2.5
## How much faster the rim pulses at the very end (1 = no speed-up)
@export var pulse_speed_up: float = 3.0

@onready var area: ColorRect = $Area

var _material: ShaderMaterial
var _duration: float = 1.0
var _time: float = 0.0
var _phase: float = 0.0
var _running: bool = false

func _ready() -> void:
	_material = area.material as ShaderMaterial
	if not _running:
		visible = false

## Show the warning centred on `at`: radius in pixels, duration in seconds
func start(radius: float, duration: float, at: Vector2) -> void:
	if not is_node_ready():
		await ready
	global_position = at
	_duration = maxf(duration, 0.01)
	_time = 0.0
	_phase = 0.0
	_running = true
	var diameter: float = roundf(radius * 2.0)
	area.position = Vector2(-diameter * 0.5, -diameter * 0.5)
	area.size = Vector2(diameter, diameter)
	if _material:
		_material.set_shader_parameter("pixel_grid", Vector2(diameter, diameter))
	_apply(0.0)
	visible = true

func stop() -> void:
	_running = false
	visible = false

func get_progress() -> float:
	return clampf(_time / _duration, 0.0, 1.0)

func _process(delta: float) -> void:
	if not _running:
		return
	_time += delta
	var progress: float = get_progress()
	_phase += delta * pulse_speed * lerpf(1.0, pulse_speed_up, progress)
	_apply(progress)
	if _time >= _duration:
		_running = false
		finished.emit()

func _apply(progress: float) -> void:
	if _material == null:
		return
	_material.set_shader_parameter("progress", progress)
	_material.set_shader_parameter("pulse", 0.5 + 0.5 * sin(_phase * TAU))

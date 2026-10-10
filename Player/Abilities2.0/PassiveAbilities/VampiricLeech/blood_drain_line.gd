class_name BleedDrainLine extends Line2D

# A short-lived blood stream from a bleeding enemy to the player.
# Follows both while it's alive, then fades and frees itself.

var source: Node2D
var target: Node2D
var last_source_position: Vector2

var fade_in: float = 0.1
var hold: float = 0.25
var fade_out: float = 0.25

func setup(_source: Node2D, _target: Node2D, _shader: Shader) -> void:
	source = _source
	target = _target
	last_source_position = source.global_position
	width = 8.0
	texture_mode = Line2D.LINE_TEXTURE_STRETCH
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = _shader
	mat.set_shader_parameter("strength", 0.0)
	material = mat
	_update_points()

func _ready() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(material, "shader_parameter/strength", 1.0, fade_in)
	tween.tween_interval(hold)
	tween.tween_property(material, "shader_parameter/strength", 0.0, fade_out)
	tween.tween_callback(queue_free)

func _process(_delta: float) -> void:
	_update_points()

func _update_points() -> void:
	# If the enemy died mid-drain, keep the line anchored where it was.
	if is_instance_valid(source):
		last_source_position = source.global_position
	if not is_instance_valid(target):
		queue_free()
		return
	points = PackedVector2Array([to_local(last_source_position), to_local(target.global_position)])

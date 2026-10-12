class_name WizardBoss extends Boss

@export var element_color: Color = Color(1.0, 0.45, 0.1)
@export var teleport_points: Array[Marker2D]
@export var spell_rotation: Array[WizardSpellState]
@export var markers: Array[NamedMarker]

var current_point: Marker2D
var _spell_index: int = 0
var _shader: ShaderMaterial

func extra_ready_functions() -> void:
	animation_player = $AnimationPlayer
	_shader = sprite.material as ShaderMaterial
	if _shader:
		_shader.set_shader_parameter("target_color", element_color)
		_shader.set_shader_parameter("frame_count", Vector2(sprite.hframes, sprite.vframes))

func _on_fight_began() -> void:
	state_machine.Initialize(self)

func next_spell() -> WizardSpellState:
	if spell_rotation.is_empty():
		return null
	var spell: WizardSpellState = spell_rotation[_spell_index]
	_spell_index = (_spell_index + 1) % spell_rotation.size()
	return spell

func set_targetable(value: bool) -> void:
	hit_box.set_deferred("monitorable", value)
	hurt_box.set_deferred("monitoring", value)

func set_side_fade(value: float) -> void:
	if _shader:
		_shader.set_shader_parameter("side_fade", value)

func get_marker(marker_id: StringName) -> NamedMarker:
	for m: NamedMarker in markers:
		if m.id == marker_id:
			return m
	return null

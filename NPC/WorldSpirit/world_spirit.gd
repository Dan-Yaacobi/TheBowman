class_name WorldSpirit extends NPC
## The hub guide. Shows a "!" while schematics wait to be revealed,
## and reveals them into known recipes when the player talks to it.

@export var schematic_marker: CanvasItem
@export var name_highlight: Color = Color(0.55, 0.8, 1.0)
@export_group("Waiting glow")
## Seconds to fade the glow in or out.
@export var glow_fade: float = 0.6
@export var marker_bob_height: float = 3.0
@export var marker_bob_speed: float = 4.0
@export_group("")

var _glow_tween: Tween
## Mirrors the shader's glow_strength (reading it back returns null until first set).
var _glow_strength: float = 0.0
var _marker_base_y: float = 0.0
var _bob_time: float = 0.0

func extra_ready_functions() -> void:
	if schematic_marker is Control:
		_marker_base_y = (schematic_marker as Control).position.y
	Crafting.schematics_changed.connect(_on_crafting_schematics_changed)
	_on_crafting_schematics_changed()

func extra_process_function(delta: float) -> void:
	if schematic_marker is Control and schematic_marker.visible:
		_bob_time += delta
		(schematic_marker as Control).position.y = _marker_base_y + sin(_bob_time * marker_bob_speed) * marker_bob_height

func on_interaction_opened() -> void:
	if not Crafting.has_unidentified():
		return
	var learned: Array[EquipmentData] = Crafting.identify_all()
	if learned.is_empty():
		return
	chat_box.show_line(_reveal_line(learned))

func _reveal_line(learned: Array[EquipmentData]) -> String:
	var names: Array[String] = []
	for template: EquipmentData in learned:
		names.append("[color=#%s]%s[/color]" % [name_highlight.to_html(false), template.display_name])
	if names.size() == 1:
		return "These lines remember a lost artifact: %s. A smith could make it whole again." % names[0]
	return "These lines remember lost artifacts: %s. A smith could make them whole again." % ", ".join(names)

func _on_crafting_schematics_changed() -> void:
	var waiting: bool = Crafting.has_unidentified()
	if schematic_marker:
		schematic_marker.visible = waiting
	_fade_glow(1.0 if waiting else 0.0)

## Drives glow_strength on the sprite's spirit_glow shader.
func _fade_glow(target: float) -> void:
	var mat: ShaderMaterial = sprite.material as ShaderMaterial if sprite else null
	if mat == null:
		return
	if _glow_tween:
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.tween_method(_set_glow.bind(mat), _glow_strength, target, glow_fade)

func _set_glow(value: float, mat: ShaderMaterial) -> void:
	_glow_strength = value
	mat.set_shader_parameter(&"glow_strength", value)

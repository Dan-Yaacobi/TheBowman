class_name WorldSpirit extends NPC
## The hub guide. Interacting opens a menu built from the SpiritOption children of Options
## (schematics, talk, later lore and quests). Shows a "!" and glows while any turn-in is waiting.

@export var turn_in_marker: CanvasItem
## Shown in the chat box while the options menu is open.
@export var greeting_line: String = ""
@export_group("Waiting glow")
## Seconds to fade the glow in or out.
@export var glow_fade: float = 0.6
@export var marker_bob_height: float = 3.0
@export var marker_bob_speed: float = 4.0
@export_group("")

@onready var menu: SpiritMenu = $SpiritMenu
@onready var options_root: Node = $Options

var _glow_tween: Tween
## Mirrors the shader's glow_strength (reading it back returns null until first set).
var _glow_strength: float = 0.0
var _marker_base_y: float = 0.0
var _bob_time: float = 0.0

func extra_ready_functions() -> void:
	if turn_in_marker is Control:
		_marker_base_y = (turn_in_marker as Control).position.y
	for option: SpiritOption in get_options():
		option.entries_changed.connect(_on_option_entries_changed)
	_on_option_entries_changed()

func extra_process_function(delta: float) -> void:
	if turn_in_marker is Control and turn_in_marker.visible:
		_bob_time += delta
		(turn_in_marker as Control).position.y = _marker_base_y + sin(_bob_time * marker_bob_speed) * marker_bob_height

func get_options() -> Array[SpiritOption]:
	var options: Array[SpiritOption] = []
	for child: Node in options_root.get_children():
		if child is SpiritOption:
			options.append(child as SpiritOption)
	return options

## Every available entry, highest priority first (stable within an option).
func get_entries() -> Array[SpiritMenuEntry]:
	var entries: Array[SpiritMenuEntry] = []
	for option: SpiritOption in get_options():
		for entry: SpiritMenuEntry in option.get_entries():
			entry.option = option
			entries.append(entry)
	# sort_custom isn't stable; break ties by original order.
	var order: Dictionary[SpiritMenuEntry, int] = {}
	for i: int in entries.size():
		order[entries[i]] = i
	entries.sort_custom(func(a: SpiritMenuEntry, b: SpiritMenuEntry) -> bool:
		if a.priority != b.priority:
			return a.priority > b.priority
		return order[a] < order[b])
	return entries

func has_turn_in() -> bool:
	for entry: SpiritMenuEntry in get_entries():
		if entry.is_turn_in:
			return true
	return false

## Plays lines in the chat box, one per Interact. Returns true if the player read to the end,
## false if the chat closed first (walked away / Exit).
func say(lines: Array[String]) -> bool:
	if lines.is_empty() or chat_box == null:
		return true
	chat_box.play_lines(data.npc_name, lines)
	var completed: bool = await chat_box.lines_finished
	return completed

func _on_option_entries_changed() -> void:
	var waiting: bool = has_turn_in()
	if turn_in_marker:
		turn_in_marker.visible = waiting
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

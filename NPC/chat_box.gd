class_name ChatBox extends CanvasLayer

@onready var chat_panel: PanelContainer = $Control/ChatPanel
@onready var name_label: Label = $Control/ChatPanel/VBoxContainer/NameLabel
@onready var dialogue_label: RichTextLabel = $Control/ChatPanel/VBoxContainer/DialogueLabel
@onready var buttons_container: HBoxContainer = $Control/ChatPanel/VBoxContainer/ButtonsContainer
@onready var continue_hint: Label = $Control/ChatPanel/VBoxContainer/ContinueHint

@export var chars_per_second: float = 40.0

var _lines: Array[String] = []
var _current_line_index: int = 0
var _is_typing: bool = false
var _tween: Tween
var is_last_line: bool = false


func _ready() -> void:
	chat_panel.visible = false
	
func open(npc: NPC) -> void:
	var random_line: String = npc.data.dialogue_lines.pick_random()
	var full_text: String = random_line
	if npc.data.fixed_line != "":
		full_text += "\n\n" + npc.data.fixed_line
	_lines = [full_text]
	_current_line_index = 0
	name_label.text = npc.data.npc_name
	chat_panel.visible = true
	_build_buttons(npc)
	_show_line(_lines[0])

func close() -> void:
	chat_panel.visible = false
	_kill_tween()
	_lines = []
	_current_line_index = 0
	is_last_line = false


func advance() -> void:
	if _is_typing:
		_snap_to_full()
		return
	if is_last_line:
		return
	_current_line_index += 1
	_show_line(_lines[_current_line_index])

func show_line(line: String) -> void:
	for child in buttons_container.get_children():
		child.queue_free()
	buttons_container.visible = false
	_lines = [line]
	_current_line_index = 0
	is_last_line = true
	_show_line(line)
	
func _show_line(line: String) -> void:
	dialogue_label.text = line
	dialogue_label.visible_ratio = 0.0
	is_last_line = _current_line_index >= _lines.size() - 1
	buttons_container.visible = false
	continue_hint.visible = false
	_is_typing = true
	_kill_tween()
	var duration: float = line.length() / chars_per_second
	_tween = create_tween()
	_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	_tween.finished.connect(_on_typing_finished, CONNECT_ONE_SHOT)

func _snap_to_full() -> void:
	_kill_tween()
	dialogue_label.visible_ratio = 1.0
	_on_typing_finished()


func _on_typing_finished() -> void:
	_is_typing = false
	buttons_container.visible = buttons_container.get_child_count() > 0
	continue_hint.visible = true
	continue_hint.text = "[E] Close" if is_last_line else "[E] Continue"


func _build_buttons(npc: NPC) -> void:
	for child in buttons_container.get_children():
		child.queue_free()
	buttons_container.visible = false
	for i in npc.data.action_button_labels.size():
		var btn := Button.new()
		btn.text = npc.data.action_button_labels[i]
		btn.pressed.connect(npc.action.bind(i))
		buttons_container.add_child(btn)


func _kill_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = null

func _input(event: InputEvent) -> void:
	if not chat_panel.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		if _is_typing:
			_snap_to_full()

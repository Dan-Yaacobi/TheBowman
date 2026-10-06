class_name UpgradeMenu extends Control

signal closed
@onready var rows: VBoxContainer = $Panel/VBox/Scroll/Rows
@onready var close_button: Button = $Panel/VBox/CloseButton

@export var row_scene: PackedScene

@export var anim_duration: float = 0.18

@onready var panel: PanelContainer = $Panel

var _is_open: bool = false
var _tween: Tween

func _ready() -> void:
	# Keeps the menu working while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(close)
	EventBus.close_upgrade_menu.connect(close)
	for track: UpgradeTrack in MetaProgress.tracks:
		var row: UpgradeRow = row_scene.instantiate() as UpgradeRow
		row.setup(track)
		rows.add_child(row)
	hide()
	EventBus.open_upgrade_menu.connect(open)
	
func open() -> void:
	if _is_open:
		return
	_is_open = true
	# Always show current resources, e.g. right after loading a save.
	for row: Node in rows.get_children():
		(row as UpgradeRow).refresh()
	show()
	panel.pivot_offset = panel.size / 2.0
	modulate.a = 0.0
	panel.scale = Vector2(0.92, 0.92)
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "modulate:a", 1.0, anim_duration)
	_tween.tween_property(panel, "scale", Vector2.ONE, anim_duration)

func close() -> void:
	if not _is_open:
		return
	_is_open = false
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, anim_duration)
	_tween.tween_property(panel, "scale", Vector2(0.92, 0.92), anim_duration)
	_tween.chain().tween_callback(hide)
	closed.emit()
	EventBus.upgrade_menu_closed.emit()
	
func _input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed("Exit"):
		close()
		get_viewport().set_input_as_handled()

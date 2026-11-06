class_name CraftMenu extends Control
## Blacksmith craft menu (lives in the HUD). Lists known recipes; one craft per run.
## Opened through EventBus.open_craft_menu by the Forge. Closes itself after a craft.

@export var row_scene: PackedScene
@export var anim_duration: float = 0.18

@onready var panel: PanelContainer = $Panel
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var rows: VBoxContainer = $Panel/VBox/Scroll/Rows
@onready var close_button: Button = $Panel/VBox/CloseButton

var _is_open: bool = false
var _drop_position: Vector2 = Vector2.ZERO
var _tween: Tween

func _ready() -> void:
	# Keeps the menu working while the game is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(close)
	EventBus.open_craft_menu.connect(open)
	EventBus.close_craft_menu.connect(close)
	hide()

func open(drop_position: Vector2) -> void:
	if _is_open:
		return
	_is_open = true
	_drop_position = drop_position
	_rebuild()
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
	EventBus.craft_menu_closed.emit()

func _rebuild() -> void:
	for child: Node in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var known: Array[EquipmentData] = Crafting.get_known_templates()
	if Crafting.crafted_this_run:
		status_label.text = "The forge has cooled. It burns again after your next run."
	elif known.is_empty():
		status_label.text = "No known schematics yet. Find them in the rifts and bring them to the spirit."
	else:
		status_label.text = "Forge one item for your next run."
	for template: EquipmentData in known:
		var row: CraftRow = row_scene.instantiate() as CraftRow
		row.setup(template)
		row.craft_pressed.connect(_on_row_craft_pressed)
		rows.add_child(row)

func _on_row_craft_pressed(template: EquipmentData) -> void:
	if Crafting.craft(template, PlayerManager.player, _drop_position):
		close()

func _input(event: InputEvent) -> void:
	if _is_open and event.is_action_pressed("Exit"):
		close()
		get_viewport().set_input_as_handled()

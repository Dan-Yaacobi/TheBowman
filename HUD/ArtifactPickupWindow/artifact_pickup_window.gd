class_name ArtifactPickupWindow extends Control
## Shows a lore artifact the player interacted with: its icon, name and pickup line, with
## Pick up / Leave. Pauses the game while open. Interact picks up, Esc leaves.
## Opened by EventBus.lore_item_inspected; answers with EventBus.lore_item_pickup_confirmed.

@onready var icon: TextureRect = %Icon
@onready var name_label: Label = %NameLabel
@onready var line_label: Label = %LineLabel
@onready var pick_up_button: Button = %PickUpButton
@onready var leave_button: Button = %LeaveButton

var _item: LoreItemData = null

func _ready() -> void:
	hide()
	pick_up_button.pressed.connect(_on_pick_up_button_pressed)
	leave_button.pressed.connect(close)
	EventBus.lore_item_inspected.connect(_on_event_bus_lore_item_inspected)

func open(item: LoreItemData) -> void:
	if item == null or get_tree().paused:
		return
	_item = item
	icon.texture = item.icon
	icon.visible = item.icon != null
	name_label.text = item.display_name
	line_label.text = item.pickup_line
	show()
	get_tree().paused = true
	pick_up_button.grab_focus.call_deferred()

func close() -> void:
	_item = null
	hide()
	get_tree().paused = false

# _input runs before the pause menu's _unhandled_input, so Esc only closes this window.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("Interact"):
		get_viewport().set_input_as_handled()
		_on_pick_up_button_pressed()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func _on_pick_up_button_pressed() -> void:
	var item: LoreItemData = _item
	close()
	if item:
		EventBus.lore_item_pickup_confirmed.emit(item)

func _on_event_bus_lore_item_inspected(item: LoreItemData) -> void:
	open(item)

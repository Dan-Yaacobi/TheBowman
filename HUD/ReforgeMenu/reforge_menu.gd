class_name ReforgeMenu extends Control
## The rogue wizard's reforge window (lives in the HUD). Pauses the game and lists the equipped
## bow, quiver and ring: each can be reforged one rarity higher for essence. Opened and answered
## through EventBus: open_reforge_menu in, reforge_slot_chosen / reforge_menu_closed out.

@export var essence_icon: Texture2D
@export var icon_size: Vector2 = Vector2(32, 32)
@export var item_icon_size: Vector2 = Vector2(40, 40)
## Costs the player can't afford are tinted this color.
@export var cant_afford_color: Color = Color(0.85, 0.35, 0.3)
@export var anim_duration: float = 0.18
## Buttons ignore input for this long after opening, so a held key can't pick by accident.
@export var input_delay: float = 0.3

@onready var panel: PanelContainer = $Panel
@onready var rows: VBoxContainer = $Panel/VBox/Rows
@onready var close_button: Button = $Panel/VBox/CloseButton

const SLOT_NAMES: Array[String] = ["Bow", "Quiver", "Ring"]

var _is_open: bool = false
var _costs: Array[int] = []
var _tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	close_button.pressed.connect(close)
	EventBus.open_reforge_menu.connect(open)
	hide()


func open(costs_by_rarity: Array[int]) -> void:
	if _is_open:
		return
	_is_open = true
	_costs = costs_by_rarity
	get_tree().paused = true
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
	get_tree().paused = false
	if _tween:
		_tween.kill()
	_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(self, "modulate:a", 0.0, anim_duration)
	_tween.tween_property(panel, "scale", Vector2(0.92, 0.92), anim_duration)
	_tween.chain().tween_callback(hide)
	EventBus.reforge_menu_closed.emit()


## Essence to reforge an item of this rarity one step up; -1 if it can't go higher.
func cost_for(rarity: int) -> int:
	var target: int = rarity + 1
	if target > EquipmentData.Rarity.LEGENDARY or target >= _costs.size():
		return -1
	return _costs[target]


func _rebuild() -> void:
	for child: Node in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	var buttons: Array[Button] = []
	for slot: int in SLOT_NAMES.size():
		var item: EquipmentData = PlayerManager.player.get_equipped_in_slot(slot as EquipmentData.slots)
		var button: Button = _add_row(slot, item)
		if button:
			buttons.append(button)
	# Brief input block, then enable whatever is affordable
	for button: Button in buttons:
		button.set_meta(&"enable", not button.disabled)
		button.disabled = true
	await get_tree().create_timer(input_delay, true).timeout
	if not is_inside_tree() or not _is_open:
		return
	for button: Button in buttons:
		if is_instance_valid(button):
			button.disabled = not button.get_meta(&"enable", false)


## One row per slot: item icon and name (rarity colored), next rarity, cost and the button.
func _add_row(slot: int, item: EquipmentData) -> Button:
	var row: PanelContainer = PanelContainer.new()
	row.theme_type_variation = &"RowPanel"
	rows.add_child(row)
	var box: HBoxContainer = HBoxContainer.new()
	box.add_theme_constant_override(&"separation", 8)
	row.add_child(box)

	var icon: TextureRect = TextureRect.new()
	icon.custom_minimum_size = item_icon_size
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(icon)

	var name_label: Label = Label.new()
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(name_label)

	if item == null:
		name_label.text = "No %s equipped" % SLOT_NAMES[slot].to_lower()
		name_label.theme_type_variation = &"DimLabel"
		return null

	icon.texture = item.texture
	name_label.text = "%s\n%s" % [item.display_name, CustomVariables.rarity_name(item.rarity)]
	name_label.add_theme_color_override(&"font_color", CustomVariables.rarity_color(item.rarity))

	var cost: int = cost_for(item.rarity)
	if cost < 0 or item.rarity >= item.max_rarity():
		var maxed: Label = Label.new()
		maxed.text = "Already legendary" if item.rarity >= EquipmentData.Rarity.LEGENDARY else "Starter gear can't be reforged"
		maxed.theme_type_variation = &"DimLabel"
		maxed.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(maxed)
		return null

	var arrow: Label = Label.new()
	arrow.text = "-> %s" % CustomVariables.rarity_name(item.rarity + 1)
	arrow.add_theme_color_override(&"font_color", CustomVariables.rarity_color(item.rarity + 1))
	arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(arrow)

	var cost_icon: TextureRect = TextureRect.new()
	cost_icon.texture = essence_icon
	cost_icon.custom_minimum_size = icon_size
	cost_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cost_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	box.add_child(cost_icon)
	var cost_label: Label = Label.new()
	cost_label.text = str(cost)
	cost_label.theme_type_variation = &"CostLabel"
	cost_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var affordable: bool = PlayerManager.player.stats.items.get(CustomVariables.items.ESSENCE, 0) >= cost
	if not affordable:
		cost_label.add_theme_color_override(&"font_color", cant_afford_color)
	box.add_child(cost_label)

	var button: Button = Button.new()
	button.text = "Reforge"
	button.custom_minimum_size = Vector2(120, 20)
	button.disabled = not affordable
	button.pressed.connect(_on_reforge_pressed.bind(slot))
	box.add_child(button)
	return button


## Mouse only (Design Rule 9): the wizard does the paying and the reforge.
func _on_reforge_pressed(slot: int) -> void:
	EventBus.button_click_sound.emit()
	EventBus.reforge_slot_chosen.emit(slot)
	close()


## Exit closes; cancel is swallowed so the pause menu can't unpause underneath.
func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("Exit"):
		close()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()

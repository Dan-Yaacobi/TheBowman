class_name CraftRow extends PanelContainer
## One known recipe in the craft menu: icon, name, cost and the craft button.

signal craft_pressed(template: EquipmentData)

## Icon for each resource, shown next to the cost amounts.
@export var item_icons: Dictionary[CustomVariables.items, Texture2D] = {}
@export var icon_size: Vector2 = Vector2(32, 32)
## Cost amounts the player can't afford are tinted this color.
@export var cant_afford_color: Color = Color(0.85, 0.35, 0.3)

@onready var item_icon: TextureRect = $HBoxContainer/ItemIcon
@onready var name_label: Label = $HBoxContainer/NameLabel
@onready var cost_box: HBoxContainer = $HBoxContainer/CostBox
@onready var craft_button: Button = $HBoxContainer/CraftButton

var template: EquipmentData

## Call before adding the row to the tree.
func setup(_template: EquipmentData) -> void:
	template = _template

func _ready() -> void:
	craft_button.pressed.connect(_on_craft_button_pressed)
	refresh()

func refresh() -> void:
	if template == null:
		return
	var player: Player = PlayerManager.player
	item_icon.texture = template.texture
	name_label.text = template.display_name
	_build_costs(Crafting.get_craft_cost(template), player.stats)
	craft_button.disabled = not Crafting.can_craft(template, player)

func _build_costs(cost: Dictionary[CustomVariables.items, int], stats: PlayerStats) -> void:
	for child: Node in cost_box.get_children():
		cost_box.remove_child(child)
		child.queue_free()
	for item: CustomVariables.items in cost:
		var amount: int = cost[item]
		var icon: TextureRect = TextureRect.new()
		icon.texture = item_icons.get(item)
		icon.custom_minimum_size = icon_size
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cost_box.add_child(icon)
		var label: Label = Label.new()
		label.text = str(amount)
		label.theme_type_variation = &"CostLabel"
		if stats.items.get(item, 0) < amount:
			label.add_theme_color_override(&"font_color", cant_afford_color)
		cost_box.add_child(label)

func _on_craft_button_pressed() -> void:
	EventBus.button_click_sound.emit()
	craft_pressed.emit(template)

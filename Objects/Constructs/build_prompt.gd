class_name BuildPrompt extends PanelContainer
## Floating window above an unbuilt construct: name, description, cost, Build button.
## Mouse only on purpose, so building is always a deliberate click.

## Icon for each resource, shown next to the cost amounts.
@export var item_icons: Dictionary[CustomVariables.items, Texture2D] = {}
@export var icon_size: Vector2 = Vector2(16, 16)
@export var cant_afford_color: Color = Color(0.85, 0.35, 0.3)
@export var fade_duration: float = 0.2

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var description_label: Label = $VBoxContainer/DescriptionLabel
@onready var cost_box: HBoxContainer = $VBoxContainer/CostBox
@onready var build_button: Button = $VBoxContainer/BuildButton

var site: ConstructSite
var _fade_tween: Tween

func _ready() -> void:
	build_button.pressed.connect(_on_build_pressed)
	# Keyboard / controller can't press it: building is mouse only.
	build_button.focus_mode = Control.FOCUS_NONE
	PlayerManager.player.item_amount_changed.connect(_on_items_changed)
	visible = false
	modulate.a = 0.0

## Called by the ConstructSite.
func setup(_site: ConstructSite) -> void:
	site = _site
	name_label.text = site.display_name
	description_label.text = site.description
	description_label.visible = site.description != ""
	refresh()

func open() -> void:
	refresh()
	visible = true
	_fade_to(1.0)

func close() -> void:
	_fade_to(0.0)

func refresh() -> void:
	if site == null:
		return
	_build_costs()
	build_button.disabled = not site.can_afford()

func _build_costs() -> void:
	for child: Node in cost_box.get_children():
		cost_box.remove_child(child)
		child.queue_free()
	var stats: PlayerStats = PlayerManager.player.stats
	for item: CustomVariables.items in site.cost:
		var amount: int = site.cost[item]

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

func _fade_to(alpha: float) -> void:
	if _fade_tween:
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", alpha, fade_duration)
	if alpha == 0.0:
		_fade_tween.tween_callback(hide)

func _on_items_changed(_amount: int, _item: CustomVariables.items) -> void:
	if visible:
		refresh()

func _on_build_pressed() -> void:
	if site == null:
		return
	EventBus.button_click_sound.emit()
	if site.try_build():
		close()

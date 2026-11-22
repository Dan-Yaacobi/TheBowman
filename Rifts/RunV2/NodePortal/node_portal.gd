class_name NodePortal extends EventPortal
## A crossroads portal: leads into the node it carries. Uses the event portal sprite, tinted
## per node type. Danger also shows through size (never color alone), the reward type through
## an icon/name above it.

## Portal size added per danger level.
@export var size_per_danger: float = 0.15
## World pixels above the portal's center where the icon and name sit.
@export var telegraph_height: float = 30.0

var node_data: RunNodeData


func setup(_node_data: RunNodeData) -> void:
	node_data = _node_data


func _ready() -> void:
	super._ready()
	if node_data == null:
		return
	animated_sprite_2d.self_modulate = node_data.portal_color
	scale *= 1.0 + size_per_danger * node_data.danger
	_add_telegraph()


func teleport_player() -> void:
	if node_data == null:
		return
	var missing: String = _missing_gear_message()
	if missing != "":
		CombatTextSpawner.spawn(global_position, missing, Color.WHITE)
		return
	EventBus.portal_entered_sound.emit()
	EventBus.node_portal_entered.emit(node_data)


## Empty when the player can enter (bow and quiver equipped).
func _missing_gear_message() -> String:
	if PlayerManager.player == null:
		return ""
	var stats: PlayerStats = PlayerManager.player.stats
	if stats.bow == null and stats.arrow == null:
		return "Equip a bow and quiver first"
	if stats.bow == null:
		return "Equip a bow first"
	if stats.arrow == null:
		return "Equip a quiver first"
	return ""


## Icon + name, kept at world scale.
func _add_telegraph() -> void:
	var holder: Node2D = Node2D.new()
	holder.scale = Vector2.ONE / scale
	holder.position = Vector2(0.0, -telegraph_height / scale.y)
	add_child(holder)
	var text: String = node_data.display_name
	if node_data.icon:
		var icon: Sprite2D = Sprite2D.new()
		icon.texture = node_data.icon
		icon.position = Vector2(0, -12)
		holder.add_child(icon)
	elif node_data.icon_text != "":
		text = "[%s]  %s" % [node_data.icon_text, text]
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 3)
	label.size = Vector2(100, 12)
	label.position = Vector2(-50, -6)
	holder.add_child(label)

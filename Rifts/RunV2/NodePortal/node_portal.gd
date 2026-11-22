class_name NodePortal extends Portal
## A crossroads portal: leads into the node it carries. Telegraphs danger through size and
## particle density (never color alone) and its reward type through an icon above it.

## Portal size added per danger level.
@export var size_per_danger: float = 0.15
## Particle amount and speed added per danger level.
@export var particles_per_danger: float = 0.5
## World pixels above the portal's base where the icon and name sit.
@export var telegraph_height: float = 44.0

var node_data: RunNodeData


func setup(_node_data: RunNodeData) -> void:
	node_data = _node_data
	if node_data:
		color = node_data.portal_color


func _ready() -> void:
	super._ready()
	if node_data == null:
		return
	scale *= 1.0 + size_per_danger * node_data.danger
	_scale_particles(1.0 + particles_per_danger * node_data.danger)
	_add_telegraph()


func enter() -> void:
	if node_data == null:
		return
	if not _has_bow_and_quiver():
		CombatTextSpawner.spawn(global_position, _missing_gear_message(), Color.WHITE)
		return
	EventBus.portal_entered_sound.emit()
	EventBus.node_portal_entered.emit(node_data)


func _leads_into_rift() -> bool:
	return node_data != null


## Crossroads portals look like the biome they're in.
func _pick_look() -> PortalLook:
	if PlayerManager.player == null:
		return null
	return _biome_look(CustomVariables.biome_index(PlayerManager.player.stats.rift_level))


func _scale_particles(factor: float) -> void:
	for child: Node in sprite.get_children():
		var particles: CPUParticles2D = child as CPUParticles2D
		if particles:
			particles.amount = maxi(roundi(particles.amount * factor), 1)
			particles.speed_scale *= factor


## Icon + name, kept at world scale (the portal root is scaled way down).
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

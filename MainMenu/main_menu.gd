class_name MainMenu extends GameWorld

@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var islands: Node2D = $Islands
@onready var loot_manager: LootManager = $LootManager
@onready var rift_portal: Portal = $Islands/Island11/RiftPortal

@export var item_data: EquipmentData
## Hub sky. Resets the sky after a run.
@export var sky_colors: SkyColors
## Equipped automatically when the player arrives with that slot empty (first launch, after death).
@export var starting_bow: EquipmentData
@export var starting_quiver: EquipmentData

func extra_set_world_functions() -> void:
	EventBus.in_main_menu.emit()
	if sky_colors:
		EventBus.change_sky_color.emit(sky_colors)
	loot_manager.set_up()
	_equip_starting_gear.call_deferred()
	
	for island in islands.get_children():
		if island is Island:
			island.setup(Rift.Type.DIRT)
	has_respawns = true
func _equip_starting_gear() -> void:
	if not is_inside_tree():
		return
	var player: Player = PlayerManager.player
	if player.stats.bow == null and starting_bow:
		_equip_starting_item(starting_bow, player)
	if player.stats.arrow == null and starting_quiver:
		_equip_starting_item(starting_quiver, player)

func _equip_starting_item(template: EquipmentData, player: Player) -> void:
	var new_equip: Equipment = template.equipment_scene.instantiate()
	new_equip.data = loot_manager.create_specific(template)
	player.add_child(new_equip)
	new_equip.equip_directly()

func extra_exit_world_functions() -> void:
	loot_manager.unset_up()
	
func spawn_position() -> Vector2:
	return player_spawn.global_position

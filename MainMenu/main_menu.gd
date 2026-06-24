class_name MainMenu extends GameWorld

@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var portals: Node2D = $Portals
@onready var islands: Node2D = $Islands
@onready var falling_death: FallingDeath = $FallingDeath
@onready var loot_manager: LootManager = $LootManager

@onready var rift_portal: Portal = $Portals/RiftPortal

func extra_set_world_functions() -> void:
	EventBus.in_main_menu.emit()
	loot_manager.set_up()
	if not PlayerManager.player.target_dummy_tutorial_passed:
		rift_portal.disable()
	EventBus.tutorial_done.connect(tutorial_done)
	
func tutorial_done() -> void:
	rift_portal.enable()
	
func extra_exit_world_functions() -> void:
	loot_manager.unset_up()
	
func spawn_position() -> Vector2:
	return player_spawn.global_position

func _on_falling_death_body_entered(body: Node2D) -> void:
	if body is Player:
		body.kill(false)
		

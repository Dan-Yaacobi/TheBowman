class_name MainMenu extends GameWorld

@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var portals: Node2D = $Portals
@onready var islands: Node2D = $Islands
@onready var falling_death: FallingDeath = $FallingDeath
@onready var loot_manager: LootManager = $LootManager

func extra_set_world_functions() -> void:
	loot_manager.set_up()
	
func extra_exit_world_functions() -> void:
	loot_manager.unset_up()
	
func spawn_position() -> Vector2:
	return player_spawn.global_position

func _on_falling_death_body_entered(body: Node2D) -> void:
	if body is Player:
		EventBus.changed_scene.emit(GameWorlds.worlds.Main_Menu)

func summon_effect(effect: Node2D) -> void:
	effects.append(effect)
	add_child(effect)

func remove_effects() -> void:
	for effect in effects:
		if is_instance_valid(effect):
			effect.queue_free()
			

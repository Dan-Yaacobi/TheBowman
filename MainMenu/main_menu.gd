class_name MainMenu extends GameWorld

@onready var wave_label: Label = $CurrentWaves
@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var portals: Node2D = $Portals
@onready var islands: Node2D = $Islands
@onready var falling_death: FallingDeath = $FallingDeath


func _ready() -> void:
	EventBus.summon_effect.connect(summon_effect)
	pass

func set_world() -> void:
	PlayerManager.player.heal(999, false)
	
func spawn_position() -> Vector2:
	return player_spawn.global_position

func _on_falling_death_body_entered(body: Node2D) -> void:
	if body is Player:
		EventBus.changed_scene.emit(GameWorlds.worlds.Main_Menu)
	pass # Replace with function body.
func summon_effect(effect: Node2D) -> void:
	add_child(effect)

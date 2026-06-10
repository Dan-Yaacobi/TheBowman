class_name GameManager extends Node2D

@export var boss_entries: Array[EnemyEntry]

const BOSS_ARENAS = {
	1: GameWorlds.worlds.Boss_Arena_1,
}

var curr_world: GameWorld
var prev_world: GameWorld

var game:Game
var hud: HUD

var _is_transitioning: bool = false


func _ready() -> void:
	EventBus.changed_scene.connect(change_game_world)
	EventBus.entered_rift_portal.connect(_on_portal_entered)

func _on_portal_entered() -> void:
	var rift_level: int = PlayerManager.player.stats.rift_level
	if rift_level %2 == 0 and not curr_world is BossArena1:
		change_game_world(GameWorlds.worlds.Boss_Arena_1)
	else:
		change_game_world(GameWorlds.worlds.Rift_1)
	
func set_game(_game: Game) -> void:
	if _game:
		game = _game
		hud = game.hud

func spawn_player(_pos: Vector2 = Vector2.ZERO) -> void:
	PlayerManager.player.camera.position_smoothing_enabled = false

	PlayerManager.player.global_position = _pos
	PlayerManager.player.camera.force_update_scroll()


func change_game_world(_new: GameWorlds.worlds) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if _new is GameWorlds.worlds:
		game.hud.visible = false
		
		await SceneTransition.fade_out()

		var next_world = GameWorlds.get_world(_new)
		
		if next_world is MainMenu:
			PlayerManager.player.stats.rift_level = 0
			
		get_tree().paused = true
		
		prev_world = curr_world
		curr_world = next_world
		
		game.add_child(curr_world)
		curr_world.set_world()
		PlayerManager.player.reparent(curr_world)
		if prev_world:
			prev_world.exit_world()
			game.remove_child(prev_world)

		spawn_player(curr_world.spawn_position())
		
		await get_tree().process_frame
		
		EventBus.invisible_hands.emit(true)
		get_tree().paused = false
		game.hud.visible = true
		PlayerManager.player.visible = true
		PlayerManager.player.camera.position_smoothing_enabled = true
		await get_tree().process_frame
		await SceneTransition.fade_in()
		curr_world.on_world_ready()
		_is_transitioning = false

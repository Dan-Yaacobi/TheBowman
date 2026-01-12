class_name GameManager extends Node2D

var curr_world: GameWorld
var prev_world: GameWorld

var game:Game
var hud: HUD

func set_game(_game: Game) -> void:
	if _game:
		game = _game


func spawn_player(_pos: Vector2 = Vector2.ZERO) -> void:
	PlayerManager.player.global_position = _pos


func change_game_world(_new: GameWorld) -> void:
	if _new:
		get_tree().paused = true

		game.hud.visible = false
		
		await SceneTransition.fade_out()
		
		prev_world = curr_world
		curr_world = _new
		
		game.add_child(curr_world)
		curr_world.set_world()
		
		if prev_world:
			prev_world.exit_world()
			game.remove_child(prev_world)
			PlayerManager.player.reparent(curr_world)

		else:
			curr_world.add_child(PlayerManager.player	)

		
		
		spawn_player(curr_world.spawn_position())
		
		await get_tree().process_frame
		
		await SceneTransition.fade_in()
		EventBus.invisible_hands.emit(true)
		get_tree().paused = false
		game.hud.visible = true
		await get_tree().process_frame

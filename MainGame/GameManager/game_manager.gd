class_name GameManager extends Node2D

@export var boss_encounters: Array[PackedScene]

var _remaining_bosses: Array[PackedScene] = []

var curr_world: GameWorld
var prev_world: GameWorld

var game: Game
var hud: HUD

var _is_transitioning: bool = false


func _ready() -> void:
	EventBus.changed_scene.connect(change_game_world)
	EventBus.entered_rift_portal.connect(_on_portal_entered)
	EventBus.event_enter_requested.connect(_on_event_enter_requested)
	EventBus.event_exit_requested.connect(_on_event_exit_requested)
	EventBus.relocate_player.connect(_place_player_and_resume)
	EventBus.boss_portal_entered.connect(func() -> void: change_to_scene(_draw_boss()))
	
func _on_portal_entered() -> void:
	var rift_level: int = PlayerManager.player.stats.rift_level
	if rift_level % CustomVariables.RIFTS_PER_TYPE == 0 and not curr_world is BossArena:
		change_to_scene(_draw_boss())
	else:
		change_game_world(GameWorlds.worlds.Rift_1)

func _draw_boss() -> PackedScene:
	if _remaining_bosses.is_empty():
		_reset_boss_pool()
	if _remaining_bosses.is_empty():
		return null
	return _remaining_bosses.pop_back()

func _reset_boss_pool() -> void:
	_remaining_bosses = boss_encounters.duplicate()
	_remaining_bosses.shuffle()

func set_game(_game: Game) -> void:
	if _game:
		game = _game
		hud = game.hud

func spawn_player(_pos: Vector2 = Vector2.ZERO) -> void:
	PlayerManager.player.camera.position_smoothing_enabled = false
	PlayerManager.player.velocity = Vector2.ZERO
	PlayerManager.player.global_position = _pos
	PlayerManager.player.camera.force_update_scroll()

# --- Shared transition halves ---

func _fade_out_and_pause() -> void:
	game.hud.visible = false
	await SceneTransition.fade_out()
	get_tree().paused = true

func _place_player_and_resume(_pos: Vector2) -> void:
	spawn_player(_pos)
	await get_tree().physics_frame
	EventBus.invisible_hands.emit(true)
	get_tree().paused = false
	game.hud.visible = true
	PlayerManager.player.visible = true
	PlayerManager.player.camera.position_smoothing_enabled = true
	await get_tree().process_frame
	await SceneTransition.fade_in()


# --- World change ---

func change_game_world(_new: GameWorlds.worlds) -> void:
	if _is_transitioning:
		return
	var next_world: GameWorld = GameWorlds.get_world(_new)
	if next_world == null:
		return
	await _transition_to(next_world)

func change_to_scene(scene: PackedScene) -> void:
	if _is_transitioning or scene == null:
		return
	var next_world: GameWorld = scene.instantiate() as GameWorld
	if next_world == null:
		push_error("Scene %s root is not a GameWorld" % scene.resource_path)
		return
	await _transition_to(next_world)

func _transition_to(next_world: GameWorld) -> void:
	_is_transitioning = true
	await _fade_out_and_pause()

	if next_world is MainMenu:
		PlayerManager.player.stats.rift_level = 0
		_reset_boss_pool()

	prev_world = curr_world
	curr_world = next_world

	game.add_child(curr_world)
	curr_world.set_world()
	if prev_world:
		prev_world.exit_world()
		game.remove_child(prev_world)

	PlayerManager.player.reparent(curr_world)
	await _place_player_and_resume(curr_world.spawn_position())

	curr_world.on_world_ready()
	EventBus.world_ready.emit()
	_is_transitioning = false

# --- Events ---

func _on_event_enter_requested(event_scene: PackedScene, return_position: Vector2) -> void:
	if _is_transitioning or not curr_world or curr_world.current_event:
		return
	_is_transitioning = true
	await _fade_out_and_pause()
	var event_spawn: Vector2 = curr_world.enter_event(event_scene, return_position)
	await _place_player_and_resume(event_spawn)
	curr_world.current_event.on_event_entered()
	_is_transitioning = false

func _on_event_exit_requested() -> void:
	if _is_transitioning or not curr_world or not curr_world.current_event:
		return
	_is_transitioning = true
	await _fade_out_and_pause()
	var return_position: Vector2 = curr_world.exit_event()
	await _place_player_and_resume(return_position)
	_is_transitioning = false
	EventBus.event_exited.emit()

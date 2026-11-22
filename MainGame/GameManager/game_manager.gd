class_name GameManager extends Node2D

## Boss arena entered after the last rift of each biome.
@export var biome_bosses: Dictionary[Rift.Type, PackedScene] = {}

@export_group("Run Structure v2")
## The hub portal starts a crossroads run instead of a procedural rift.
@export var use_run_v2: bool = true
@export var nodes_per_act: int = 5

const CROSSROADS_SCENE_PATH: String = "res://Rifts/RunV2/Crossroads/Crossroads.tscn"

var curr_world: GameWorld
var prev_world: GameWorld

var game: Game
var hud: HUD

var _is_transitioning: bool = false
## The current v2 run; null outside one (hub, tutorial, procedural rifts).
var _route: RunRoute = null


func _ready() -> void:
	EventBus.changed_scene.connect(change_game_world)
	EventBus.entered_rift_portal.connect(_on_portal_entered)
	EventBus.event_enter_requested.connect(_on_event_enter_requested)
	EventBus.event_exit_requested.connect(_on_event_exit_requested)
	EventBus.relocate_player.connect(_place_player_and_resume)
	EventBus.boss_portal_entered.connect(func() -> void: change_to_scene(_draw_boss()))
	EventBus.node_portal_entered.connect(_on_node_portal_entered)
	
func _on_portal_entered() -> void:
	if _route != null:
		_on_route_exit_portal_entered()
		return
	var rift_level: int = PlayerManager.player.stats.rift_level
	if rift_level % CustomVariables.RIFTS_PER_TYPE == 0 and not curr_world is BossArena:
		change_to_scene(_draw_boss())
	else:
		change_game_world(GameWorlds.worlds.Rift_1)

## Picks the boss matching the biome of the rift the player is leaving.
func _draw_boss() -> PackedScene:
	var biome: Rift.Type = Rift.Type.DIRT
	var rift: Rift = curr_world as Rift
	if _route != null:
		biome = _route.get_biome()
	elif rift:
		biome = rift.get_rift_type()
	if not biome_bosses.has(biome):
		push_error("No boss assigned for biome %s" % Rift.Type.keys()[biome])
		return null
	return biome_bosses[biome]

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
	# Deferred: this can run inside a physics callback (falling into the void), where
	# changing a collision shape directly errors.
	PlayerManager.player.collision_shape.set_deferred("disabled", true)
	spawn_player(_pos)
	await get_tree().physics_frame
	EventBus.invisible_hands.emit(true)
	get_tree().paused = false
	# Unpausing re-adds the player to physics at its last position for one step, so collision
	# stays off until it has synced to the new spot (see _transition_to).
	await get_tree().physics_frame
	PlayerManager.player.collision_shape.disabled = false
	game.hud.visible = true
	PlayerManager.player.visible = true
	PlayerManager.player.camera.position_smoothing_enabled = true
	await get_tree().process_frame
	await SceneTransition.fade_in()


# --- World change ---

func change_game_world(_new: GameWorlds.worlds) -> void:
	if _is_transitioning:
		return
	if use_run_v2 and _new == GameWorlds.worlds.Rift_1 and curr_world is MainMenu:
		_start_route()
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
		_route = null

	prev_world = curr_world
	curr_world = next_world

	# The player still stands at its old position while the new world loads in. Without this,
	# areas there (e.g. a boss arena's FallingDeath) register the player and cost a heart.
	PlayerManager.player.collision_shape.disabled = true
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
	EventBus.event_entered.emit()

func _on_event_exit_requested() -> void:
	# An event played as a run node: its exit leads on to the next crossroads.
	if _route != null and curr_world is EventNode:
		_on_route_exit_portal_entered()
		return
	if _is_transitioning or not curr_world or not curr_world.current_event:
		return
	_is_transitioning = true
	await _fade_out_and_pause()
	var return_position: Vector2 = curr_world.exit_event()
	await _place_player_and_resume(return_position)
	_is_transitioning = false
	EventBus.event_exited.emit()


# --- Run Structure v2 ---

func _start_route() -> void:
	_route = RunRoute.new(nodes_per_act)
	_go_to_crossroads()

func _go_to_crossroads() -> void:
	if _is_transitioning:
		return
	var scene: PackedScene = load(CROSSROADS_SCENE_PATH)
	var crossroads: Crossroads = scene.instantiate() as Crossroads if scene else null
	if crossroads == null:
		push_error("Crossroads scene missing or not a Crossroads: %s" % CROSSROADS_SCENE_PATH)
		return
	# Set before the world is built: islands and portals read their biome from it.
	PlayerManager.player.stats.rift_level = _route.get_equivalent_rift_level()
	crossroads.set_route(_route)
	await _transition_to(crossroads)

func _on_node_portal_entered(node: RunNodeData) -> void:
	if _is_transitioning or _route == null or node == null:
		return
	if node.scene == null:
		push_error("Run node '%s' has no scene" % node.display_name)
		return
	var world: GameWorld = node.scene.instantiate() as GameWorld
	if world == null:
		push_error("Run node '%s' scene root is not a GameWorld" % node.display_name)
		return
	_route.enter_node(node)
	# Set before the world is built: islands and portals read their biome from it.
	PlayerManager.player.stats.rift_level = _route.get_equivalent_rift_level()
	if world is RunNodeWorld:
		(world as RunNodeWorld).set_route(_route)
	await _transition_to(world)

## A node's or a boss arena's exit portal (both are rift portals).
func _on_route_exit_portal_entered() -> void:
	if _is_transitioning:
		return
	if curr_world is BossArena:
		_route.finish_act()
		if _route.is_run_finished():
			# The hell boss exit leads to the Tower once it exists; back to the hub until then.
			change_game_world(GameWorlds.worlds.Main_Menu)
			return
		_go_to_crossroads()
		return
	_route.complete_node()
	if _route.is_act_finished():
		change_to_scene(_draw_boss())
	else:
		_go_to_crossroads()

class_name Tutorial extends GameWorld
## New-game tutorial. The world spirit walks the player through one skill at a time:
## jump, dash, falling, sword, bow (hit, then perfect shot), the stats screen and the menu.
## Each step plays the spirit's lines (Interact advances), then shows a goal until it is met.
## Falls return the player to the last island they stood on. Dying rebuilds this world
## at the step the player had reached. Finishing or skipping refills hearts, writes the
## first save (so the next launch goes straight to the hub) and sends the player to the hub.

enum Step { INTRO, JUMP, DASH, FALL, SWORD, BOW, BOW_HIT, PERFECT_SHOT, STATS, MENU, OUTRO, DONE }

## Survives the world being rebuilt after a death, so the player resumes where they were.
static var _resume_step: Step = Step.INTRO

@export var sky_colors: SkyColors
@export var bow_template: EquipmentData
@export var quiver_template: EquipmentData
@export var crate_scene: PackedScene
## Where the spirit hovers, relative to the checkpoint of the current step.
@export var spirit_offset: Vector2 = Vector2(-55.0, -40.0)
## Seconds the spirit takes to drift to its next spot.
@export var spirit_move_time: float = 1.2
## Dropped gear below this height has fallen into the void and is dropped again.
@export var gear_lost_y: float = 300.0
## Horizontal gap between the dropped bow and quiver, so their pickups don't overlap.
@export var gear_spacing: float = 28.0

@export_group("Lines")
@export var intro_lines: Array[String] = []
@export var jump_lines: Array[String] = []
@export var dash_lines: Array[String] = []
@export var fall_lines: Array[String] = []
## Played instead of fall_lines when the player already fell before the fall step.
@export var already_fell_lines: Array[String] = []
@export var after_fall_lines: Array[String] = []
@export var sword_lines: Array[String] = []
@export var bow_lines: Array[String] = []
@export var bow_hit_lines: Array[String] = []
@export var perfect_shot_lines: Array[String] = []
@export var stats_lines: Array[String] = []
@export var menu_lines: Array[String] = []
@export var outro_lines: Array[String] = []
@export_group("Goals")
@export var jump_goal: String = ""
@export var dash_goal: String = ""
@export var fall_goal: String = ""
@export var sword_goal: String = ""
@export var gear_goal: String = ""
@export var bow_hit_goal: String = ""
@export var perfect_shot_goal: String = ""
@export var stats_goal: String = ""
@export var menu_goal: String = ""
@export_group("")

@onready var spirit: WorldSpirit = $WorldSpirit
@onready var loot_manager: LootManager = $LootManager
@onready var start_checkpoint: Marker2D = $Checkpoints/Start
@onready var jump_checkpoint: Marker2D = $Checkpoints/Jump
@onready var dash_checkpoint: Marker2D = $Checkpoints/Dash
@onready var jump_islands: Array[Island] = [$Islands/Jump1, $Islands/Jump2]
@onready var dash_islands: Array[Island] = [$Islands/Dash1, $Islands/Dash2, $Islands/Dash3]
@onready var crate_spot: Marker2D = $Markers/CrateSpot
@onready var gear_spot: Marker2D = $Markers/GearSpot
@onready var target_dummy: TargetDummy = $Islands/Target/TargetDummy
@onready var goal_label: Label = $TutorialHud/GoalLabel
@onready var skip_button: Button = $TutorialHud/SkipButton

var _step: Step = Step.INTRO
## True while the spirit's lines are playing; Interact advances them.
var _talking: bool = false
var _finished: bool = false
var _has_fallen: bool = false
var _target_hit: bool = false
var _perfect_hit: bool = false
var _opened_stats: bool = false
var _opened_menu: bool = false
var _spirit_tween: Tween

func extra_set_world_functions() -> void:
	death_world = GameWorlds.worlds.Tutorial
	counts_as_run = false
	has_respawns = true
	_step = _resume_step
	respawn_position = spawn_position()
	if sky_colors:
		EventBus.change_sky_color.emit(sky_colors)
	loot_manager.set_up()
	# The spirit only talks when the tutorial tells it to; no hub menu here.
	spirit.npc_state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	spirit.keyboard_press_helper.hide()
	spirit.global_position = _checkpoint_for(_step).global_position + spirit_offset
	goal_label.hide()
	skip_button.pressed.connect(_on_skip_button_pressed)
	EventBus.player_fell.connect(_on_event_bus_player_fell)
	EventBus.arrow_enemy_hit.connect(_on_event_bus_arrow_enemy_hit)

func extra_exit_world_functions() -> void:
	loot_manager.unset_up()
	EventBus.player_fell.disconnect(_on_event_bus_player_fell)
	EventBus.arrow_enemy_hit.disconnect(_on_event_bus_arrow_enemy_hit)

func on_world_ready() -> void:
	# Rebuilt after a death past the bow step: dying dropped the gear, hand it back.
	if _step > Step.BOW:
		_equip_directly(bow_template)
		_equip_directly(quiver_template)
	_run_steps()

func spawn_position() -> Vector2:
	return _checkpoint_for(_step).global_position

func _checkpoint_for(step: Step) -> Marker2D:
	if step <= Step.JUMP:
		return start_checkpoint
	if step == Step.DASH:
		return jump_checkpoint
	return dash_checkpoint

# --- Step runner -----------------------------------------------------------------

func _run_steps() -> void:
	while _step != Step.DONE:
		_move_spirit_to(_checkpoint_for(_step))
		await _play_step(_step)
		if _finished or not is_inside_tree():
			return
		_step = (_step + 1) as Step
		_resume_step = _step
	_finish()

func _play_step(step: Step) -> void:
	match step:
		Step.INTRO:
			await _say(intro_lines)
		Step.JUMP:
			await _say(jump_lines)
			await _goal(jump_goal, func() -> bool: return _stood_on(jump_islands))
		Step.DASH:
			await _say(dash_lines)
			await _goal(dash_goal, func() -> bool: return _stood_on(dash_islands))
		Step.FALL:
			await _play_fall_step()
		Step.SWORD:
			await _say(sword_lines)
			var crate: GameObject = _spawn_crate()
			await _goal(sword_goal, func() -> bool: return not is_instance_valid(crate) or crate.got_hit)
		Step.BOW:
			await _play_bow_step()
		Step.BOW_HIT:
			await _say(bow_hit_lines)
			_target_hit = false
			await _goal(bow_hit_goal, func() -> bool: return _target_hit)
		Step.PERFECT_SHOT:
			await _say(perfect_shot_lines)
			_perfect_hit = false
			await _goal(perfect_shot_goal, func() -> bool: return _perfect_hit)
		Step.STATS:
			await _say(stats_lines)
			_opened_stats = false
			await _goal(stats_goal, func() -> bool: return _opened_stats and not get_tree().paused)
		Step.MENU:
			await _say(menu_lines)
			_opened_menu = false
			await _goal(menu_goal, func() -> bool: return _opened_menu and not get_tree().paused)
		Step.OUTRO:
			await _say(outro_lines)

func _play_fall_step() -> void:
	if _has_fallen:
		await _say(already_fell_lines)
	else:
		await _say(fall_lines)
		await _goal(fall_goal, func() -> bool: return _has_fallen)
	await _say(after_fall_lines)

func _play_bow_step() -> void:
	await _say(bow_lines)
	if not is_inside_tree():
		return
	var dropped: Array[Equipment] = []
	if PlayerManager.player.stats.bow == null:
		dropped.append(_drop_gear(bow_template, _gear_position(0)))
	if PlayerManager.player.stats.arrow == null:
		dropped.append(_drop_gear(quiver_template, _gear_position(1)))
	await _goal(gear_goal, func() -> bool: return _gear_ready(dropped))

## True once the player holds a bow and quiver. Re-drops any that fell into the void.
func _gear_ready(dropped: Array[Equipment]) -> bool:
	var stats: PlayerStats = PlayerManager.player.stats
	if stats.bow and stats.arrow:
		return true
	for i: int in dropped.size():
		var equip: Equipment = dropped[i]
		if is_instance_valid(equip) and equip.is_inside_tree() and equip.global_position.y > gear_lost_y:
			var data: EquipmentData = equip.data
			equip.queue_free()
			dropped[i] = drop_equipment(data, _gear_position(i))
	return false

# --- Helpers -------------------------------------------------------------------

func _stood_on(islands: Array[Island]) -> bool:
	for island: Island in islands:
		if island.stepped_on:
			return true
	return false

func _spawn_crate() -> GameObject:
	var crate: GameObject = crate_scene.instantiate() as GameObject
	add_child(crate)
	# Sit the crate's placement marker on the spot, the same way islands place objects.
	var marker_offset: Vector2 = crate.placement_marker.global_position - crate.global_position
	crate.global_position = crate_spot.global_position - marker_offset
	return crate

func _drop_gear(template: EquipmentData, at: Vector2) -> Equipment:
	return drop_equipment(loot_manager.create_specific(template), at)

func _gear_position(index: int) -> Vector2:
	return gear_spot.global_position + Vector2(gear_spacing * index, 0.0)

func _equip_directly(template: EquipmentData) -> void:
	var equip: Equipment = template.equipment_scene.instantiate()
	equip.data = loot_manager.create_specific(template)
	PlayerManager.player.add_child(equip)
	equip.equip_directly()

func _move_spirit_to(checkpoint: Marker2D) -> void:
	var target: Vector2 = checkpoint.global_position + spirit_offset
	if spirit.global_position.is_equal_approx(target):
		return
	if _spirit_tween:
		_spirit_tween.kill()
	_spirit_tween = create_tween()
	_spirit_tween.tween_property(spirit, "global_position", target, spirit_move_time) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

# --- Dialogue and goals ------------------------------------------------------------

## Plays lines in the spirit's chat box; Interact advances. Returns once the last line is read.
func _say(lines: Array[String]) -> void:
	if lines.is_empty() or not is_inside_tree():
		return
	_talking = true
	await spirit.say(lines)
	_talking = false
	if is_inside_tree():
		spirit.chat_box.close()

## Shows the goal text and waits until done() returns true (checked every frame).
func _goal(text: String, done: Callable) -> void:
	if not is_inside_tree():
		return
	goal_label.text = text
	goal_label.show()
	while is_inside_tree() and not _finished and not done.call():
		await get_tree().process_frame
	goal_label.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not _talking or not event.is_action_pressed("Interact"):
		return
	var chat: ChatBox = spirit.chat_box
	if chat.is_last_line and not chat._is_typing:
		chat.finish_lines()
	else:
		chat.advance()
	get_viewport().set_input_as_handled()

## Sees TAB / ESC before the menus open and pause the tree.
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("EquipmentMenu"):
		_opened_stats = true
	elif event.is_action_pressed("ui_cancel"):
		_opened_menu = true

func _on_event_bus_player_fell(_heart_lost: bool) -> void:
	_has_fallen = true

func _on_event_bus_arrow_enemy_hit(perfect: bool, _arrow: Arrow, target: Enemy) -> void:
	if target != target_dummy:
		return
	_target_hit = true
	if perfect:
		_perfect_hit = true

# --- Leaving -------------------------------------------------------------------

func _on_skip_button_pressed() -> void:
	# A death already has its own way back here; don't race it.
	if PlayerManager.player.is_dead():
		return
	_finish()

func _finish() -> void:
	if _finished:
		return
	_finished = true
	_resume_step = Step.INTRO
	goal_label.hide()
	PlayerManager.player.refresh_max_hp()
	SaveService.save_game()
	EventBus.changed_scene.emit(GameWorlds.worlds.Main_Menu)

class_name Tutorial extends GameWorld
## New-game tutorial. The world spirit walks the player through one skill at a time.
## Falls return the player to the last island they stood on. Dying rebuilds this world
## at the step the player had reached. Finishing or skipping refills hearts, writes the
## first save (so the next launch goes straight to the hub) and sends the player to the hub.

enum Step { INTRO, JUMP, DASH, FALL, SWORD, BOW, PERFECT_SHOT, OUTRO, DONE }

## Survives the world being rebuilt after a death, so the player resumes where they were.
static var _resume_step: Step = Step.INTRO

@export var sky_colors: SkyColors
@export_group("Lines")
@export var intro_lines: Array[String] = []
@export var outro_lines: Array[String] = []
@export_group("")

@onready var spirit: WorldSpirit = $WorldSpirit
@onready var player_spawn: PlayerSpawn = $PlayerSpawn
@onready var goal_label: Label = $TutorialHud/GoalLabel
@onready var skip_button: Button = $TutorialHud/SkipButton

var _step: Step = Step.INTRO
## True while the spirit's lines are playing; Interact advances them.
var _talking: bool = false
var _finished: bool = false

func extra_set_world_functions() -> void:
	death_world = GameWorlds.worlds.Tutorial
	counts_as_run = false
	has_respawns = true
	respawn_position = spawn_position()
	if sky_colors:
		EventBus.change_sky_color.emit(sky_colors)
	# The spirit only talks when the tutorial tells it to; no hub menu here.
	spirit.npc_state_machine.process_mode = Node.PROCESS_MODE_DISABLED
	spirit.keyboard_press_helper.hide()
	goal_label.hide()
	skip_button.pressed.connect(_on_skip_button_pressed)
	_step = _resume_step

func on_world_ready() -> void:
	_run_steps()

func spawn_position() -> Vector2:
	return player_spawn.global_position

# --- Step runner -----------------------------------------------------------------

func _run_steps() -> void:
	while _step != Step.DONE:
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
		Step.OUTRO:
			await _say(outro_lines)

# --- Dialogue and goals ------------------------------------------------------------

## Plays lines in the spirit's chat box; Interact advances. Returns once the last line is read.
func _say(lines: Array[String]) -> void:
	if lines.is_empty():
		return
	_talking = true
	await spirit.say(lines)
	_talking = false
	if is_inside_tree():
		spirit.chat_box.close()

func _unhandled_input(event: InputEvent) -> void:
	if not _talking or not event.is_action_pressed("Interact"):
		return
	var chat: ChatBox = spirit.chat_box
	if chat.is_last_line and not chat._is_typing:
		chat.finish_lines()
	else:
		chat.advance()
	get_viewport().set_input_as_handled()

func _set_goal(text: String) -> void:
	goal_label.text = text
	goal_label.show()

func _clear_goal() -> void:
	goal_label.hide()

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
	_clear_goal()
	PlayerManager.player.refresh_max_hp()
	SaveService.save_game()
	EventBus.changed_scene.emit(GameWorlds.worlds.Main_Menu)

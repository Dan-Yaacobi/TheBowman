class_name PauseMenu extends CanvasLayer

# --- Node refs (main panel buttons) ---
@onready var main_panel: Control = $Control/MainPanel
@onready var resume_button: Button = $Control/MainPanel/VBox/ResumeButton
@onready var stats_button: Button = $Control/MainPanel/VBox/StatsButton
@onready var artifacts_button: Button = $Control/MainPanel/VBox/ArtifactsButton
@onready var settings_button: Button = $Control/MainPanel/VBox/SettingsButton
@onready var restart_button: Button = $Control/MainPanel/VBox/RestartButton
@onready var exit_button: Button = $Control/MainPanel/VBox/ExitButton

# --- Artifact journal ---
@onready var artifact_journal: ArtifactJournal = $Control/ArtifactJournal
@onready var feedback_button: Button = $Control/Feedback

# --- Settings panel ---
@onready var settings_panel: Control = $Control/SettingsPanel
@onready var settings_back: Button = $Control/SettingsPanel/VBox/BackButton
@onready var fullscreen_toggle: CheckButton = $Control/SettingsPanel/VBox/FullscreenToggle
@onready var music_toggle: CheckButton = $Control/SettingsPanel/VBox/MusicToggle
@onready var sfx_toggle: CheckButton = $Control/SettingsPanel/VBox/SfxToggle
@onready var data_toggle: CheckButton = $Control/SettingsPanel/VBox/DataToggle
@onready var player_id_button: Button = $Control/SettingsPanel/VBox/PlayerIdButton

# --- Restart confirm panel ---
@onready var restart_confirm_panel: Control = $Control/RestartConfirmPanel
@onready var restart_yes: Button = $Control/RestartConfirmPanel/VBox/YesButton
@onready var restart_no: Button = $Control/RestartConfirmPanel/VBox/NoButton
@onready var restart_confirm_label: Label = $Control/RestartConfirmPanel/VBox/SubLabel

# ---

const COPIED_TEXT_SEC: float = 1.5
const START_MENU_SCENE: String = "res://StartMenu/StartMenu.tscn"
const RESTART_CONFIRM_TEXT: String = "Your current run will end."
const EXIT_CONFIRM_TEXT: String = "Your current run will end. Everything you keep between runs is saved."

enum PauseState { CLOSED, MAIN, SETTINGS, RESTART_CONFIRM, JOURNAL }

var _state: PauseState = PauseState.CLOSED
var _equipment_menu: EquipmentMenu
## The journal was opened by the spirit: Back closes the menu instead of returning to MAIN.
var _journal_requested: bool = false
var _is_exiting: bool = false
## What the confirm panel's Yes does (Restart or Save & Exit).
var _confirm_action: Callable


func setup(equipment_menu: EquipmentMenu) -> void:
	_equipment_menu = equipment_menu


func _ready() -> void:
	resume_button.pressed.connect(_close)
	stats_button.pressed.connect(_open_stats)
	artifacts_button.pressed.connect(_set_state.bind(PauseState.JOURNAL))
	artifact_journal.closed.connect(_on_artifact_journal_closed)
	EventBus.artifact_journal_requested.connect(_on_event_bus_artifact_journal_requested)
	settings_button.pressed.connect(_set_state.bind(PauseState.SETTINGS))
	restart_button.pressed.connect(_ask_confirm.bind(_on_restart_confirmed, RESTART_CONFIRM_TEXT))
	restart_yes.pressed.connect(_on_restart_yes_pressed)
	restart_no.pressed.connect(_set_state.bind(PauseState.MAIN))
	exit_button.pressed.connect(_on_exit_button_pressed)

	settings_back.pressed.connect(_set_state.bind(PauseState.MAIN))

	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	music_toggle.toggled.connect(_on_music_toggled)
	sfx_toggle.toggled.connect(_on_sfx_toggled)
	data_toggle.toggled.connect(_on_data_toggled)
	player_id_button.pressed.connect(_on_player_id_button_pressed)

	_set_state(PauseState.CLOSED)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	match _state:
		PauseState.CLOSED:
			# Close EquipmentMenu if open, then open pause menu
			_equipment_menu.close()
			_set_state(PauseState.MAIN)
		PauseState.MAIN:
			_close()
		PauseState.SETTINGS, PauseState.RESTART_CONFIRM:
			_set_state(PauseState.MAIN)
		PauseState.JOURNAL:
			_on_artifact_journal_closed()

	get_viewport().set_input_as_handled()


func _set_state(new_state: PauseState) -> void:
	_state = new_state

	main_panel.visible = (_state == PauseState.MAIN)
	settings_panel.visible = (_state == PauseState.SETTINGS)
	restart_confirm_panel.visible = (_state == PauseState.RESTART_CONFIRM)
	artifact_journal.visible = (_state == PauseState.JOURNAL)
	feedback_button.visible = (_state != PauseState.JOURNAL)

	var is_open: bool = (_state != PauseState.CLOSED)
	visible = is_open
	get_tree().paused = is_open

	if _state == PauseState.SETTINGS:
		_sync_settings_ui()
	if _state == PauseState.JOURNAL:
		artifact_journal.refresh()
	if _state == PauseState.MAIN:
		# Only offered during a run; in the hub and tutorial there is nothing to abandon.
		restart_button.visible = _is_in_run()


func _close() -> void:
	_set_state(PauseState.CLOSED)


func _on_event_bus_artifact_journal_requested() -> void:
	_equipment_menu.close()
	_journal_requested = true
	_set_state(PauseState.JOURNAL)


func _on_artifact_journal_closed() -> void:
	if _journal_requested:
		_journal_requested = false
		_close()
		EventBus.artifact_journal_closed.emit()
	else:
		_set_state(PauseState.MAIN)


func _ask_confirm(action: Callable, text: String) -> void:
	_confirm_action = action
	restart_confirm_label.text = text
	_set_state(PauseState.RESTART_CONFIRM)


func _on_restart_yes_pressed() -> void:
	if _confirm_action.is_valid():
		_confirm_action.call()


## Ends the run through the regular death flow (same as dying).
func _on_restart_confirmed() -> void:
	_close()
	PlayerManager.player.kill()


## Mid-run, leaving ends the run, so it asks first like Restart.
func _on_exit_button_pressed() -> void:
	if _is_in_run():
		_ask_confirm(_exit_to_start_menu, EXIT_CONFIRM_TEXT)
	else:
		_exit_to_start_menu()


func _is_in_run() -> bool:
	var world: Node = PlayerManager.player.get_parent()
	return not (world is MainMenu or world is Tutorial)


## Saves and goes back to the start menu. A run in progress ends there (no death screen) and
## a fresh blessing waits at the spirit, the same as closing the game mid-run.
## The player lives in the PlayerManager autoload, so it's reset and taken out of the world
## before the game scene is freed; the next Game picks it up again like on launch.
func _exit_to_start_menu() -> void:
	var player: Player = PlayerManager.player
	if _is_exiting or player.is_dead():
		return
	_is_exiting = true
	_close()
	get_tree().paused = true
	await SceneTransition.fade_out()
	var world: GameWorld = player.get_parent() as GameWorld
	# The tutorial writes the first save when it's finished; saving early would skip it next launch.
	var should_save: bool = not world is Tutorial
	MetaProgress.leave_run()
	if world:
		world.exit_world()
	player.reset_run()
	player.reset_hands()
	player.reset_knockback()
	player.velocity = Vector2.ZERO
	player.movement_locked = false
	player.stats.rift_level = 0
	player.player_state_machine.ChangeState(player.dead.idle)
	if should_save:
		SaveService.save_game()
	player.get_parent().remove_child(player)
	player.visible = false
	get_tree().paused = false
	get_tree().change_scene_to_file(START_MENU_SCENE)
	SceneTransition.fade_in()


func _open_stats() -> void:
	# Close pause menu first so the two panels don't stack.
	# EquipmentMenu manages its own pause state.
	_set_state(PauseState.CLOSED)
	_equipment_menu.open(PlayerManager.player.stats)


func _sync_settings_ui() -> void:
	# Block signals so setting button_pressed doesn't fire toggled callbacks
	for toggle: CheckButton in [fullscreen_toggle, music_toggle, sfx_toggle, data_toggle]:
		toggle.set_block_signals(true)
	fullscreen_toggle.button_pressed = SettingsManager.is_fullscreen()
	music_toggle.button_pressed = SettingsManager.is_music_enabled()
	sfx_toggle.button_pressed = SettingsManager.is_sfx_enabled()
	data_toggle.button_pressed = RunTracker.uploader.has_consent()
	for toggle: CheckButton in [fullscreen_toggle, music_toggle, sfx_toggle, data_toggle]:
		toggle.set_block_signals(false)
	_sync_player_id()


## The ID only exists (and is only shown) while the player shares stats.
func _sync_player_id() -> void:
	var player_id: String = RunTracker.uploader.player_id
	player_id_button.visible = not player_id.is_empty()
	player_id_button.text = "Player ID (click to copy)\n" + player_id


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)


func _on_music_toggled(enabled: bool) -> void:
	SettingsManager.set_music_enabled(enabled)


func _on_sfx_toggled(enabled: bool) -> void:
	SettingsManager.set_sfx_enabled(enabled)


func _on_data_toggled(enabled: bool) -> void:
	RunTracker.uploader.set_consent(enabled)
	_sync_player_id()


func _on_player_id_button_pressed() -> void:
	DisplayServer.clipboard_set(RunTracker.uploader.player_id)
	player_id_button.text = "Copied!"
	await get_tree().create_timer(COPIED_TEXT_SEC).timeout
	if is_inside_tree() and _state == PauseState.SETTINGS:
		_sync_player_id()


func _on_feedback_pressed() -> void:
	OS.shell_open("https://game-feedback-app.vercel.app/")

class_name PauseMenu extends CanvasLayer

# --- Node refs (main panel buttons) ---
@onready var main_panel: Control = $Control/MainPanel
@onready var resume_button: Button = $Control/MainPanel/VBox/ResumeButton
@onready var stats_button: Button = $Control/MainPanel/VBox/StatsButton
@onready var artifacts_button: Button = $Control/MainPanel/VBox/ArtifactsButton
@onready var how_to_play_button: Button = $Control/MainPanel/VBox/HowToPlayButton
@onready var settings_button: Button = $Control/MainPanel/VBox/SettingsButton
@onready var restart_button: Button = $Control/MainPanel/VBox/RestartButton

# --- How To Play panel ---
@onready var how_to_play_panel: Control = $Control/HowToPlayPanel
@onready var how_to_play_back: Button = $Control/HowToPlayPanel/VBox/BackButton

# --- Artifact journal ---
@onready var artifact_journal: ArtifactJournal = $Control/ArtifactJournal
@onready var feedback_button: Button = $Control/Feedback

# --- Settings panel ---
@onready var settings_panel: Control = $Control/SettingsPanel
@onready var settings_back: Button = $Control/SettingsPanel/VBox/BackButton
@onready var fullscreen_toggle: CheckButton = $Control/SettingsPanel/VBox/FullscreenToggle
@onready var music_toggle: CheckButton = $Control/SettingsPanel/VBox/MusicToggle
@onready var sfx_toggle: CheckButton = $Control/SettingsPanel/VBox/SfxToggle

# --- Restart confirm panel ---
@onready var restart_confirm_panel: Control = $Control/RestartConfirmPanel
@onready var restart_yes: Button = $Control/RestartConfirmPanel/VBox/YesButton
@onready var restart_no: Button = $Control/RestartConfirmPanel/VBox/NoButton

# ---

enum PauseState { CLOSED, MAIN, HOW_TO_PLAY, SETTINGS, RESTART_CONFIRM, JOURNAL }

var _state: PauseState = PauseState.CLOSED
var _equipment_menu: EquipmentMenu
## The journal was opened by the spirit: Back closes the menu instead of returning to MAIN.
var _journal_requested: bool = false


func setup(equipment_menu: EquipmentMenu) -> void:
	_equipment_menu = equipment_menu


func _ready() -> void:
	resume_button.pressed.connect(_close)
	stats_button.pressed.connect(_open_stats)
	how_to_play_button.pressed.connect(_set_state.bind(PauseState.HOW_TO_PLAY))
	artifacts_button.pressed.connect(_set_state.bind(PauseState.JOURNAL))
	artifact_journal.closed.connect(_on_artifact_journal_closed)
	EventBus.artifact_journal_requested.connect(_on_event_bus_artifact_journal_requested)
	settings_button.pressed.connect(_set_state.bind(PauseState.SETTINGS))
	restart_button.pressed.connect(_set_state.bind(PauseState.RESTART_CONFIRM))
	restart_yes.pressed.connect(_on_restart_yes_pressed)
	restart_no.pressed.connect(_set_state.bind(PauseState.MAIN))

	how_to_play_back.pressed.connect(_set_state.bind(PauseState.MAIN))
	settings_back.pressed.connect(_set_state.bind(PauseState.MAIN))

	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	music_toggle.toggled.connect(_on_music_toggled)
	sfx_toggle.toggled.connect(_on_sfx_toggled)

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
		PauseState.HOW_TO_PLAY, PauseState.SETTINGS, PauseState.RESTART_CONFIRM:
			_set_state(PauseState.MAIN)
		PauseState.JOURNAL:
			_on_artifact_journal_closed()

	get_viewport().set_input_as_handled()


func _set_state(new_state: PauseState) -> void:
	_state = new_state

	main_panel.visible = (_state == PauseState.MAIN)
	how_to_play_panel.visible = (_state == PauseState.HOW_TO_PLAY)
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
		# Only offered during a run; in the hub there is nothing to abandon.
		restart_button.visible = not PlayerManager.player.get_parent() is MainMenu


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


## Ends the run through the regular death flow (same as dying).
func _on_restart_yes_pressed() -> void:
	_close()
	PlayerManager.player.kill()


func _open_stats() -> void:
	# Close pause menu first so the two panels don't stack.
	# EquipmentMenu manages its own pause state.
	_set_state(PauseState.CLOSED)
	_equipment_menu.open(PlayerManager.player.stats)


func _sync_settings_ui() -> void:
	# Block signals so setting button_pressed doesn't fire toggled callbacks
	for toggle: CheckButton in [fullscreen_toggle, music_toggle, sfx_toggle]:
		toggle.set_block_signals(true)
	fullscreen_toggle.button_pressed = SettingsManager.is_fullscreen()
	music_toggle.button_pressed = SettingsManager.is_music_enabled()
	sfx_toggle.button_pressed = SettingsManager.is_sfx_enabled()
	for toggle: CheckButton in [fullscreen_toggle, music_toggle, sfx_toggle]:
		toggle.set_block_signals(false)


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)


func _on_music_toggled(enabled: bool) -> void:
	SettingsManager.set_music_enabled(enabled)


func _on_sfx_toggled(enabled: bool) -> void:
	SettingsManager.set_sfx_enabled(enabled)


func _on_feedback_pressed() -> void:
	OS.shell_open("https://game-feedback-app.vercel.app/")

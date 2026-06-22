class_name PauseMenu extends CanvasLayer

# --- Node refs (main panel buttons) ---
@onready var main_panel: Control = $Control/MainPanel
@onready var resume_button: Button = $Control/MainPanel/VBox/ResumeButton
@onready var stats_button: Button = $Control/MainPanel/VBox/StatsButton
@onready var how_to_play_button: Button = $Control/MainPanel/VBox/HowToPlayButton
@onready var settings_button: Button = $Control/MainPanel/VBox/SettingsButton

# --- How To Play panel ---
@onready var how_to_play_panel: Control = $Control/HowToPlayPanel
@onready var how_to_play_back: Button = $Control/HowToPlayPanel/VBox/BackButton

# --- Settings panel ---
@onready var settings_panel: Control = $Control/SettingsPanel
@onready var settings_back: Button = $Control/SettingsPanel/VBox/BackButton
@onready var fullscreen_toggle: CheckButton = $Control/SettingsPanel/VBox/FullscreenToggle
@onready var mute_toggle: CheckButton = $Control/SettingsPanel/VBox/MuteToggle

# ---

enum PauseState { CLOSED, MAIN, HOW_TO_PLAY, SETTINGS }

var _state: PauseState = PauseState.CLOSED
var _equipment_menu: EquipmentMenu


func setup(equipment_menu: EquipmentMenu) -> void:
	_equipment_menu = equipment_menu


func _ready() -> void:
	resume_button.pressed.connect(_close)
	stats_button.pressed.connect(_open_stats)
	how_to_play_button.pressed.connect(_set_state.bind(PauseState.HOW_TO_PLAY))
	settings_button.pressed.connect(_set_state.bind(PauseState.SETTINGS))

	how_to_play_back.pressed.connect(_set_state.bind(PauseState.MAIN))
	settings_back.pressed.connect(_set_state.bind(PauseState.MAIN))

	fullscreen_toggle.toggled.connect(_on_fullscreen_toggled)
	mute_toggle.toggled.connect(_on_mute_toggled)

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
		PauseState.HOW_TO_PLAY, PauseState.SETTINGS:
			_set_state(PauseState.MAIN)

	get_viewport().set_input_as_handled()


func _set_state(new_state: PauseState) -> void:
	_state = new_state

	main_panel.visible = (_state == PauseState.MAIN)
	how_to_play_panel.visible = (_state == PauseState.HOW_TO_PLAY)
	settings_panel.visible = (_state == PauseState.SETTINGS)

	var is_open: bool = (_state != PauseState.CLOSED)
	visible = is_open
	get_tree().paused = is_open

	if _state == PauseState.SETTINGS:
		_sync_settings_ui()


func _close() -> void:
	_set_state(PauseState.CLOSED)


func _open_stats() -> void:
	# Close pause menu first so the two panels don't stack.
	# EquipmentMenu manages its own pause state.
	_set_state(PauseState.CLOSED)
	_equipment_menu.open(PlayerManager.player.stats)


func _sync_settings_ui() -> void:
	# Block signals so setting button_pressed doesn't fire toggled callbacks
	fullscreen_toggle.set_block_signals(true)
	mute_toggle.set_block_signals(true)
	fullscreen_toggle.button_pressed = SettingsManager.is_fullscreen()
	mute_toggle.button_pressed = SettingsManager.is_muted()
	fullscreen_toggle.set_block_signals(false)
	mute_toggle.set_block_signals(false)


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)


func _on_mute_toggled(muted: bool) -> void:
	SettingsManager.set_muted(muted)

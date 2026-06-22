extends Node

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "settings"

var _config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_load()
	apply_all()

func _on_node_added(node: Node) -> void:
	if node is Button:
		node.pressed.connect(func(): EventBus.button_click_sound.emit())

func apply_all() -> void:
	_apply_fullscreen()
	_apply_mute()


# --- Fullscreen ---

func set_fullscreen(enabled: bool) -> void:
	_config.set_value(SECTION, "fullscreen", enabled)
	_save()
	_apply_fullscreen()


func is_fullscreen() -> bool:
	return _config.get_value(SECTION, "fullscreen", false)


func _apply_fullscreen() -> void:
	if is_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# --- Mute ---

func set_muted(muted: bool) -> void:
	_config.set_value(SECTION, "muted", muted)
	_save()
	_apply_mute()


func is_muted() -> bool:
	return _config.get_value(SECTION, "muted", false)


func _apply_mute() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), is_muted())


# --- Persistence ---

func _save() -> void:
	_config.save(SETTINGS_PATH)


func _load() -> void:
	var err: int = _config.load(SETTINGS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("SettingsManager: failed to load settings.cfg (error %d)" % err)

extends Node

const SETTINGS_PATH: String = "user://settings.cfg"
const SECTION: String = "settings"
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"

var _config: ConfigFile = ConfigFile.new()

func _ready() -> void:
	_create_audio_buses()
	# Autoloads before this one (SoundManager) are already in the tree.
	_route_existing(get_tree().root)
	get_tree().node_added.connect(_on_node_added)
	_load()
	apply_all()

func _on_node_added(node: Node) -> void:
	if node is Button:
		node.pressed.connect(func(): EventBus.button_click_sound.emit())
	else:
		_route_audio(node)

## Music players are put on the Music bus in their scenes; every other player is a sound effect.
func _route_audio(node: Node) -> void:
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		if node.bus == &"Master":
			node.bus = SFX_BUS

func _route_existing(node: Node) -> void:
	_route_audio(node)
	for child: Node in node.get_children():
		_route_existing(child)

func apply_all() -> void:
	_apply_fullscreen()
	_apply_audio()


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


# --- Audio ---

## Music and SFX buses both feed Master. Made here so no bus layout file is needed.
func _create_audio_buses() -> void:
	for bus_name: StringName in [MUSIC_BUS, SFX_BUS]:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var index: int = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, &"Master")

func set_music_enabled(enabled: bool) -> void:
	_config.set_value(SECTION, "music_enabled", enabled)
	_save()
	_apply_audio()

func is_music_enabled() -> bool:
	return _config.get_value(SECTION, "music_enabled", true)

func set_sfx_enabled(enabled: bool) -> void:
	_config.set_value(SECTION, "sfx_enabled", enabled)
	_save()
	_apply_audio()

func is_sfx_enabled() -> bool:
	return _config.get_value(SECTION, "sfx_enabled", true)

func _apply_audio() -> void:
	AudioServer.set_bus_mute(AudioServer.get_bus_index(MUSIC_BUS), not is_music_enabled())
	AudioServer.set_bus_mute(AudioServer.get_bus_index(SFX_BUS), not is_sfx_enabled())


# --- Persistence ---

func _save() -> void:
	_config.save(SETTINGS_PATH)


func _load() -> void:
	var err: int = _config.load(SETTINGS_PATH)
	if err != OK and err != ERR_FILE_NOT_FOUND:
		push_warning("SettingsManager: failed to load settings.cfg (error %d)" % err)

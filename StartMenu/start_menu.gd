class_name StartMenu extends Control
## Everything from launch until the game starts: intro, main menu, save slots,
## settings and credits. Every choice is confirmed by a big arrow shot from the
## viewer's side of the screen into the chosen button.

const GAME_SCENE: String = "res://MainGame/Game.tscn"
const MENU_ARROW_SCENE: PackedScene = preload("res://StartMenu/MenuArrow/MenuArrow.tscn")
## Matches MenuArrow.flight_time; times things that run beside a non-blocking arrow.
const MENU_ARROW_FLIGHT: float = 0.26

enum Screen { MAIN, SLOTS, SETTINGS, CREDITS }

@export_group("Feel")
## Seconds between the arrow landing and the menu reacting.
@export var hit_pause: float = 0.14
@export var screen_slide: float = 80.0
@export var screen_time: float = 0.22
@export var focus_scale: float = 1.06
@export var focus_time: float = 0.12
@export var shake_strength: float = 8.0
@export var shake_time: float = 0.16
## How far the title drifts with the mouse, in pixels.
@export var parallax_strength: float = 22.0
@export var intro_time: float = 1.3
## How far from the screen's middle (min, max) arrows are launched, on the side away from the target.
@export var launch_spread: Vector2 = Vector2(220.0, 520.0)
@export_group("")

# --- Backdrop ---
@onready var backdrop: Control = %Backdrop
@onready var scenery: MenuScenery = %Scenery
# --- UI ---
@onready var ui_root: Control = %UIRoot
@onready var title_root: Control = %TitleRoot
@onready var title_label: Label = %TitleLabel
@onready var tagline: Label = %Tagline
@onready var arrows: Node2D = %Arrows
@onready var focus_cursor: Sprite2D = %FocusCursor
# --- Screens ---
@onready var main_screen: Control = %MainScreen
@onready var slots_screen: Control = %SlotsScreen
@onready var settings_screen: Control = %SettingsScreen
@onready var credits_screen: Control = %CreditsScreen
# --- Main ---
@onready var main_buttons: VBoxContainer = %MainButtons
@onready var continue_button: Button = %ContinueButton
@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var credits_button: Button = %CreditsButton
@onready var quit_button: Button = %QuitButton
# --- Slots ---
@onready var slot_cards: HBoxContainer = %SlotCards
@onready var slots_back_button: Button = %SlotsBackButton
@onready var erase_dialog: Control = %EraseDialog
@onready var erase_panel: Control = %ErasePanel
@onready var erase_title: Label = %EraseTitle
@onready var erase_yes_button: Button = %EraseYesButton
@onready var erase_no_button: Button = %EraseNoButton
# --- Settings ---
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var music_toggle: CheckButton = %MusicToggle
@onready var sfx_toggle: CheckButton = %SfxToggle
@onready var data_toggle: CheckButton = %DataToggle
@onready var settings_back_button: Button = %SettingsBackButton
# --- Credits ---
@onready var credits_scroll: ScrollContainer = %CreditsScroll
@onready var credits_back_button: Button = %CreditsBackButton
# --- Other ---
@onready var consent: DataConsent = $DataConsent
@onready var menu_music: AudioStreamPlayer = $MenuMusic
@onready var whoosh_sound: AudioStreamPlayer = $WhooshSound
@onready var thunk_sound: AudioStreamPlayer = $ThunkSound
@onready var twang_sound: AudioStreamPlayer = $TwangSound
@onready var focus_sound: AudioStreamPlayer = $FocusSound

var _screen: Screen = Screen.MAIN
var _screens: Dictionary[Screen, Control] = {}
## True while an arrow is flying or a screen is changing. Input waits.
var _busy: bool = true
var _intro_tween: Tween
var _intro_playing: bool = false
var _erase_card: SaveSlotCard
var _cards: Array[SaveSlotCard] = []
var _focus_tweens: Dictionary[Button, Tween] = {}
var _cursor_target: Control
var _time: float = 0.0
## Last focus owner, so focus sounds only play on real changes.
var _last_focus: Control
var _title_drift: Vector2 = Vector2.ZERO
var _consent_closing: bool = false
var _changing_screen: bool = false
## Set once the menu is starting the game or quitting: the scenery stops taking shots.
var _leaving: bool = false

func _ready() -> void:
	_screens = {
		Screen.MAIN: main_screen,
		Screen.SLOTS: slots_screen,
		Screen.SETTINGS: settings_screen,
		Screen.CREDITS: credits_screen,
	}
	for card: Node in slot_cards.get_children():
		if card is SaveSlotCard:
			_cards.append(card)
			card.chosen.connect(_on_card_chosen)
			card.erase_requested.connect(_on_card_erase_requested)

	continue_button.pressed.connect(_on_continue_button_pressed)
	play_button.pressed.connect(_on_play_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	credits_button.pressed.connect(_on_credits_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)
	slots_back_button.pressed.connect(_on_back_button_pressed.bind(slots_back_button))
	settings_back_button.pressed.connect(_on_back_button_pressed.bind(settings_back_button))
	credits_back_button.pressed.connect(_on_back_button_pressed.bind(credits_back_button))
	erase_yes_button.pressed.connect(_on_erase_yes_button_pressed)
	erase_no_button.pressed.connect(_on_erase_no_button_pressed)
	fullscreen_toggle.toggled.connect(_on_fullscreen_toggle_toggled)
	music_toggle.toggled.connect(_on_music_toggle_toggled)
	sfx_toggle.toggled.connect(_on_sfx_toggle_toggled)
	data_toggle.toggled.connect(_on_data_toggle_toggled)
	for toggle: CheckButton in [fullscreen_toggle, music_toggle, sfx_toggle, data_toggle]:
		toggle.pressed.connect(_flourish.bind(toggle))

	scenery.arrow_landed.connect(_on_scenery_arrow_landed)
	consent.hide_on_answer = false
	consent.answered.connect(_on_consent_answered)
	consent.yes_button.pressed.connect(_flourish.bind(consent.yes_button))
	consent.no_button.pressed.connect(_flourish.bind(consent.no_button))
	_trap_focus([consent.yes_button, consent.no_button])
	_trap_focus([erase_yes_button, erase_no_button])

	_hook_button_fx(self)
	quit_button.visible = not OS.has_feature("web")
	_refresh_continue()

	for screen: Screen in _screens:
		_screens[screen].visible = screen == Screen.MAIN
	erase_dialog.hide()
	focus_cursor.modulate.a = 0.0
	_play_intro()

func _process(delta: float) -> void:
	_time += delta
	_update_parallax(delta)
	_update_focus_cursor(delta)

## Any key or click skips the intro. Uses _input so buttons and the background can't swallow it.
func _input(event: InputEvent) -> void:
	if _intro_playing and _intro_tween and _is_skip_input(event):
		_intro_tween.custom_step(intro_time * 2.0)
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if _intro_playing:
		return
	if _busy:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		if consent.visible:
			return
		if erase_dialog.visible:
			erase_no_button.grab_focus()
			_on_erase_no_button_pressed()
			return
		match _screen:
			Screen.SLOTS:
				_on_back_button_pressed(slots_back_button)
			Screen.SETTINGS:
				_on_back_button_pressed(settings_back_button)
			Screen.CREDITS:
				_on_back_button_pressed(credits_back_button)
		return

	# Nothing focused (e.g. the mouse wandered off): the first arrow key picks the default.
	var directional: bool = event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down") \
			or event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right")
	if directional and get_viewport().gui_get_focus_owner() == null:
		_focus_default()
		get_viewport().set_input_as_handled()

# --- Intro ----------------------------------------------------------------

func _play_intro() -> void:
	_busy = true
	_intro_playing = true
	backdrop.modulate = Color.BLACK
	title_label.modulate.a = 0.0
	tagline.modulate.a = 0.0
	for button: Node in main_buttons.get_children():
		(button as Control).modulate.a = 0.0
	# Containers and anchors settle on the first frame; animate from there.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	title_label.pivot_offset = title_label.size * 0.5
	scenery.zoom = 1.18
	title_label.scale = Vector2.ONE * 1.6

	_intro_tween = create_tween().set_parallel()
	_intro_tween.tween_property(backdrop, "modulate", Color.WHITE, intro_time * 0.6)
	_intro_tween.tween_property(scenery, "zoom", 1.0, intro_time).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(title_label, "modulate:a", 1.0, 0.3).set_delay(0.25)
	_intro_tween.tween_property(title_label, "scale", Vector2.ONE, 0.55).set_delay(0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_intro_tween.tween_property(tagline, "modulate:a", 1.0, 0.4).set_delay(0.6)
	var delay: float = 0.55
	for button: Node in main_buttons.get_children():
		var control: Control = button as Control
		if not control.visible:
			continue
		var rest_x: float = control.position.x
		control.position.x = rest_x + 140.0
		_intro_tween.tween_property(control, "modulate:a", 1.0, 0.25).set_delay(delay)
		_intro_tween.tween_property(control, "position:x", rest_x, 0.4).set_delay(delay).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		delay += 0.07
	await _intro_tween.finished
	if not is_inside_tree():
		return
	_intro_playing = false
	if consent.visible:
		_open_consent()
	else:
		_busy = false
		_focus_default()

func _is_skip_input(event: InputEvent) -> bool:
	if event is InputEventKey or event is InputEventJoypadButton:
		return event.is_pressed() and not event.is_echo()
	if event is InputEventMouseButton:
		return event.is_pressed()
	return false

# --- Consent --------------------------------------------------------------

func _open_consent() -> void:
	_busy = false
	var panel: Control = consent.get_node("Panel") as Control
	panel.pivot_offset = panel.size * 0.5
	consent.modulate.a = 0.0
	panel.scale = Vector2.ONE * 0.85
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(consent, "modulate:a", 1.0, 0.2)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	consent.yes_button.grab_focus()

func _on_consent_answered(_accepted: bool) -> void:
	if _consent_closing:
		return
	_consent_closing = true
	_busy = true
	# The arrow from _flourish is already on its way; let it land before closing.
	await get_tree().create_timer(MENU_ARROW_FLIGHT + hit_pause + 0.1).timeout
	if not is_inside_tree():
		return
	var tween: Tween = create_tween()
	tween.tween_property(consent, "modulate:a", 0.0, 0.2)
	await tween.finished
	consent.hide()
	_clear_arrows(consent)
	_busy = false
	_focus_default()

# --- Main screen ----------------------------------------------------------

func _refresh_continue() -> void:
	var slot: int = SaveService.get_continue_slot()
	continue_button.visible = slot >= 0
	continue_button.text = "Continue  -  Slot %d" % (slot + 1)

func _on_continue_button_pressed() -> void:
	var arrow: MenuArrow = await _choose(continue_button)
	if arrow:
		_start_game(SaveService.get_continue_slot(), arrow)

func _on_play_button_pressed() -> void:
	var arrow: MenuArrow = await _choose(play_button)
	if arrow:
		_show_screen(Screen.SLOTS, arrow, true)

func _on_settings_button_pressed() -> void:
	var arrow: MenuArrow = await _choose(settings_button)
	if arrow:
		_show_screen(Screen.SETTINGS, arrow, true)

func _on_credits_button_pressed() -> void:
	var arrow: MenuArrow = await _choose(credits_button)
	if arrow:
		_show_screen(Screen.CREDITS, arrow, true)

func _on_quit_button_pressed() -> void:
	var arrow: MenuArrow = await _choose(quit_button)
	if not arrow:
		return
	_leaving = true
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(self, "modulate", Color.BLACK, 0.35)
	tween.tween_property(menu_music, "volume_db", -40.0, 0.35)
	await tween.finished
	get_tree().quit()

func _on_back_button_pressed(button: Button) -> void:
	var arrow: MenuArrow = await _choose(button)
	if arrow:
		_show_screen(Screen.MAIN, arrow, false)

# --- Slots ----------------------------------------------------------------

func _on_card_chosen(card: SaveSlotCard) -> void:
	var arrow: MenuArrow = await _choose(card.select_button, Vector2(0.5, 0.22))
	if arrow:
		_start_game(card.slot, arrow)

func _on_card_erase_requested(card: SaveSlotCard) -> void:
	var arrow: MenuArrow = await _choose(card.erase_button)
	if not arrow:
		return
	arrow.vanish()
	_erase_card = card
	_open_erase_dialog()

func _open_erase_dialog() -> void:
	erase_title.text = "Erase Slot %d?" % (_erase_card.slot + 1)
	erase_dialog.show()
	erase_dialog.modulate.a = 0.0
	erase_panel.pivot_offset = erase_panel.size * 0.5
	erase_panel.scale = Vector2.ONE * 0.85
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(erase_dialog, "modulate:a", 1.0, 0.16)
	tween.tween_property(erase_panel, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	erase_no_button.grab_focus()
	await tween.finished
	_busy = false

func _close_erase_dialog() -> void:
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(erase_dialog, "modulate:a", 0.0, 0.16)
	tween.tween_property(erase_panel, "scale", Vector2.ONE * 0.9, 0.16)
	await tween.finished
	erase_dialog.hide()
	# Yes/No arrows are reparented onto the panel.
	_clear_arrows(erase_panel)

func _on_erase_yes_button_pressed() -> void:
	var arrow: MenuArrow = await _choose(erase_yes_button)
	if not arrow:
		return
	arrow.reparent(erase_panel)
	var card: SaveSlotCard = _erase_card
	SaveService.delete_slot(card.slot)
	_refresh_continue()
	await _close_erase_dialog()
	await _poof_card(card)
	card.get_focus_target().grab_focus()
	_busy = false

func _on_erase_no_button_pressed() -> void:
	var arrow: MenuArrow = await _choose(erase_no_button)
	if not arrow:
		return
	arrow.reparent(erase_panel)
	await _close_erase_dialog()
	_erase_card.get_focus_target().grab_focus()
	_busy = false

## The erased card collapses and comes back empty.
func _poof_card(card: SaveSlotCard) -> void:
	card.body.pivot_offset = card.body.size * 0.5
	var tween: Tween = create_tween()
	tween.tween_property(card.body, "scale", Vector2(1.1, 0.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_callback(card.refresh)
	tween.tween_property(card.body, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tween.finished

# --- Settings -------------------------------------------------------------

func _sync_settings() -> void:
	var toggles: Array[CheckButton] = [fullscreen_toggle, music_toggle, sfx_toggle, data_toggle]
	for toggle: CheckButton in toggles:
		toggle.set_block_signals(true)
	fullscreen_toggle.button_pressed = SettingsManager.is_fullscreen()
	music_toggle.button_pressed = SettingsManager.is_music_enabled()
	sfx_toggle.button_pressed = SettingsManager.is_sfx_enabled()
	data_toggle.button_pressed = RunTracker.uploader.has_consent()
	for toggle: CheckButton in toggles:
		toggle.set_block_signals(false)

func _on_fullscreen_toggle_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)

func _on_music_toggle_toggled(enabled: bool) -> void:
	SettingsManager.set_music_enabled(enabled)

func _on_sfx_toggle_toggled(enabled: bool) -> void:
	SettingsManager.set_sfx_enabled(enabled)

func _on_data_toggle_toggled(enabled: bool) -> void:
	RunTracker.uploader.set_consent(enabled)

# --- Screens --------------------------------------------------------------

## Slides the current screen out and `screen` in. The arrow that chose it leaves with the old screen.
func _show_screen(screen: Screen, arrow: MenuArrow, forward: bool) -> void:
	var outgoing: Control = _screens[_screen]
	var incoming: Control = _screens[screen]
	_screen = screen
	_changing_screen = true
	if arrow:
		arrow.reparent(outgoing)
	match screen:
		Screen.SLOTS:
			for card: SaveSlotCard in _cards:
				card.refresh()
		Screen.SETTINGS:
			_sync_settings()
		Screen.MAIN:
			_refresh_continue()
		Screen.CREDITS:
			credits_scroll.scroll_vertical = 0

	var direction: float = -1.0 if forward else 1.0
	var out_tween: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	out_tween.tween_property(outgoing, "modulate:a", 0.0, screen_time)
	out_tween.tween_property(outgoing, "position:x", screen_slide * direction, screen_time)
	await out_tween.finished
	outgoing.hide()
	outgoing.position.x = 0.0
	outgoing.modulate.a = 1.0
	_clear_arrows(outgoing)

	incoming.position.x = -screen_slide * direction
	incoming.modulate.a = 0.0
	incoming.show()
	_focus_default()
	var in_tween: Tween = create_tween().set_parallel().set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	in_tween.tween_property(incoming, "modulate:a", 1.0, screen_time)
	in_tween.tween_property(incoming, "position:x", 0.0, screen_time * 1.6)
	await get_tree().create_timer(screen_time * 0.5).timeout
	_changing_screen = false
	await in_tween.finished
	_busy = false

func _focus_default() -> void:
	var target: Control
	if consent.visible:
		target = consent.yes_button
	elif erase_dialog.visible:
		target = erase_no_button
	else:
		match _screen:
			Screen.MAIN:
				target = continue_button if continue_button.visible else play_button
			Screen.SLOTS:
				var slot: int = maxi(SaveService.get_continue_slot(), 0)
				target = _cards[slot].get_focus_target()
			Screen.SETTINGS:
				target = fullscreen_toggle
			Screen.CREDITS:
				target = credits_back_button
	if target:
		_last_focus = target
		target.grab_focus()

## Keeps keyboard focus inside a dialog's buttons.
func _trap_focus(buttons: Array[Button]) -> void:
	for i: int in buttons.size():
		var button: Button = buttons[i]
		var previous: Button = buttons[(i - 1 + buttons.size()) % buttons.size()]
		var next: Button = buttons[(i + 1) % buttons.size()]
		button.focus_neighbor_left = button.get_path_to(previous)
		button.focus_neighbor_right = button.get_path_to(next)
		button.focus_neighbor_top = button.get_path_to(button)
		button.focus_neighbor_bottom = button.get_path_to(button)
		button.focus_previous = button.get_path_to(previous)
		button.focus_next = button.get_path_to(next)

# --- Starting the game ----------------------------------------------------

func _start_game(slot: int, arrow: MenuArrow) -> void:
	_busy = true
	_leaving = true
	SaveService.select_slot(slot)
	var screen: Control = _screens[_screen]
	arrow.reparent(screen)
	scenery.zoom_focus = scenery.get_portal_point()
	# Keeps running while the tree is paused for the scene change.
	var tween: Tween = create_tween().set_parallel().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(ui_root, "modulate:a", 0.0, 0.3).set_delay(0.08)
	tween.tween_property(focus_cursor, "modulate:a", 0.0, 0.1)
	tween.tween_property(scenery, "zoom", 2.4, 0.75).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tween.tween_property(menu_music, "volume_db", -40.0, 0.7)
	await get_tree().create_timer(0.5).timeout
	get_tree().paused = true
	await SceneTransition.fade_out()
	get_tree().change_scene_to_file(GAME_SCENE)
	await SceneTransition.fade_in()
	get_tree().paused = false
	await get_tree().process_frame

# --- Arrows ---------------------------------------------------------------

## Shoots an arrow into `target` and waits for it to land. Returns the stuck arrow,
## or null if the menu was busy (the press is ignored).
## `aim` is where on the target to hit, as a fraction of its size.
func _choose(target: Control, aim: Vector2 = Vector2(0.5, 0.5)) -> MenuArrow:
	if _busy or _intro_playing:
		return null
	_busy = true
	var arrow: MenuArrow = await _shoot_at(target, aim)
	if not is_inside_tree():
		return null
	await get_tree().create_timer(hit_pause).timeout
	if not is_inside_tree():
		return null
	return arrow

## An arrow for things that act immediately (toggles, consent): doesn't block input.
func _flourish(target: Control) -> void:
	if _intro_playing:
		return
	var arrow: MenuArrow = await _shoot_at(target, Vector2(0.5, 0.5))
	if not is_inside_tree() or not is_instance_valid(arrow):
		return
	if arrow.get_parent() == arrows:
		arrow.reparent(_screen_of(target))
	await get_tree().create_timer(0.5).timeout
	if is_instance_valid(arrow):
		arrow.vanish()

func _shoot_at(target: Control, aim: Vector2) -> MenuArrow:
	var arrow: MenuArrow = MENU_ARROW_SCENE.instantiate()
	arrows.add_child(arrow)
	var viewport_size: Vector2 = get_viewport_rect().size
	var to_inverse: Transform2D = arrows.get_global_transform().affine_inverse()
	var jitter: Vector2 = Vector2(randf_range(-0.12, 0.12), randf_range(-0.12, 0.12))
	var hit_global: Vector2 = target.get_global_rect().position + target.get_global_rect().size * (aim + jitter * Vector2(1.0, 0.6))
	# From just below the bottom edge, on the far side from the target: the viewer's side
	# of the screen, so the arrow cuts diagonally across into it.
	var side: float = -signf(hit_global.x - viewport_size.x * 0.5)
	if is_zero_approx(side):
		side = 1.0 if randf() < 0.5 else -1.0
	var from_global: Vector2 = Vector2(viewport_size.x * 0.5 + side * randf_range(launch_spread.x, launch_spread.y), viewport_size.y + 220.0)
	whoosh_sound.pitch_scale = randf_range(0.95, 1.1)
	whoosh_sound.play()
	await arrow.fire(to_inverse * from_global, to_inverse * hit_global, to_inverse * (viewport_size * 0.5))
	if not is_inside_tree():
		return arrow
	thunk_sound.pitch_scale = randf_range(0.9, 1.05)
	thunk_sound.play()
	twang_sound.pitch_scale = randf_range(0.95, 1.15)
	twang_sound.play()
	_shake()
	_squash(target)
	_crack(target, hit_global)
	return arrow

func _shake() -> void:
	var tween: Tween = create_tween()
	var steps: int = 5
	for i: int in steps:
		var strength: float = shake_strength * (1.0 - float(i) / steps)
		var offset: Vector2 = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * strength
		tween.tween_property(ui_root, "position", offset, shake_time / steps)
	tween.tween_property(ui_root, "position", Vector2.ZERO, shake_time / steps)

func _squash(target: Control) -> void:
	var node: Control = target
	# Slot cards squash their whole body, not just the invisible button on top.
	if target.owner is SaveSlotCard and target == (target.owner as SaveSlotCard).select_button:
		node = (target.owner as SaveSlotCard).body
	node.pivot_offset = node.size * 0.5
	var rest: Vector2 = node.scale
	var tween: Tween = create_tween()
	tween.tween_property(node, "scale", rest * Vector2(1.08, 0.9), 0.05)
	tween.tween_property(node, "scale", rest, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var flash: Tween = create_tween()
	var base_modulate: Color = node.self_modulate
	flash.tween_property(node, "self_modulate", Color(1.7, 1.6, 1.4), 0.04)
	flash.tween_property(node, "self_modulate", base_modulate, 0.2)

## Cracks splinter out of the button where the arrow hit. They stay until the screen changes.
func _crack(target: Control, at: Vector2) -> void:
	var crack: ButtonCrack = ButtonCrack.new()
	crack.radius = minf(target.size.y * 0.55, 34.0)
	target.add_child(crack)
	crack.global_position = at

## Frees the stuck arrows on `parent` and the cracks anywhere under it.
func _clear_arrows(parent: Node) -> void:
	for child: Node in parent.get_children():
		if child is MenuArrow:
			child.queue_free()
	for crack: Node in get_tree().get_nodes_in_group(ButtonCrack.GROUP):
		if parent.is_ancestor_of(crack):
			crack.queue_free()

func _screen_of(node: Node) -> Node:
	var current: Node = node
	while current:
		if current in _screens.values() or current == consent or current == erase_panel:
			return current
		current = current.get_parent()
	return arrows

# --- Focus feel -----------------------------------------------------------

## Every button: hover grabs focus, focus looks like hover, and focus pops the button.
func _hook_button_fx(node: Node) -> void:
	for child: Node in node.get_children():
		if child is Button:
			var button: Button = child
			button.mouse_entered.connect(_on_button_mouse_entered.bind(button))
			# Slot cards animate themselves; their select button is an invisible overlay.
			var is_card_overlay: bool = button.owner is SaveSlotCard and button == (button.owner as SaveSlotCard).select_button
			if not is_card_overlay:
				button.focus_entered.connect(_on_button_focus_changed.bind(button, true))
				button.focus_exited.connect(_on_button_focus_changed.bind(button, false))
			button.focus_entered.connect(_on_any_focus_entered.bind(button))
		_hook_button_fx(child)

func _on_button_mouse_entered(button: Button) -> void:
	if not _busy and button.is_visible_in_tree() and button.focus_mode != Control.FOCUS_NONE:
		button.grab_focus()

func _on_any_focus_entered(button: Button) -> void:
	if button != _last_focus and not _intro_playing:
		focus_sound.pitch_scale = randf_range(1.35, 1.5)
		focus_sound.play()
	_last_focus = button

func _on_button_focus_changed(button: Button, focused: bool) -> void:
	if focused:
		button.add_theme_stylebox_override(&"normal", button.get_theme_stylebox(&"hover"))
		button.add_theme_color_override(&"font_color", button.get_theme_color(&"font_hover_color"))
	else:
		button.remove_theme_stylebox_override(&"normal")
		button.remove_theme_color_override(&"font_color")
	button.pivot_offset = button.size * 0.5
	if _focus_tweens.has(button) and _focus_tweens[button].is_valid():
		_focus_tweens[button].kill()
	var tween: Tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2.ONE * (focus_scale if focused else 1.0), focus_time)
	_focus_tweens[button] = tween

## A small arrow points at whatever has focus, gliding between buttons.
func _update_focus_cursor(delta: float) -> void:
	var owner_control: Control = get_viewport().gui_get_focus_owner()
	# Slot cards show focus with their own lift and glow.
	var is_card: bool = owner_control != null and owner_control.owner is SaveSlotCard \
			and owner_control == (owner_control.owner as SaveSlotCard).select_button
	var show_cursor: bool = owner_control != null and owner_control.is_visible_in_tree() \
			and not _intro_playing and not _changing_screen and not is_card
	var target_alpha: float = 1.0 if show_cursor else 0.0
	focus_cursor.modulate.a = move_toward(focus_cursor.modulate.a, target_alpha, delta * 8.0)
	if not show_cursor:
		_cursor_target = null
		return
	var rect: Rect2 = owner_control.get_global_rect()
	var point: Vector2 = ui_root.get_global_transform().affine_inverse() * Vector2(rect.position.x - 10.0, rect.get_center().y)
	if _cursor_target == null or focus_cursor.modulate.a < 0.05:
		focus_cursor.position = point
	else:
		focus_cursor.position = focus_cursor.position.lerp(point, 1.0 - exp(-24.0 * delta))
	_cursor_target = owner_control
	focus_cursor.offset.x = -15.0 + sin(_time * 7.0) * 2.0

# --- Backdrop -------------------------------------------------------------

## A click that no button or panel took: shoot it into the scenery.
func _gui_input(event: InputEvent) -> void:
	if _intro_playing or _leaving:
		return
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		whoosh_sound.pitch_scale = randf_range(0.95, 1.1)
		whoosh_sound.play()
		scenery.shoot(click.global_position)
		accept_event()

func _on_scenery_arrow_landed(target: MenuTarget) -> void:
	if target == null:
		return
	thunk_sound.pitch_scale = randf_range(0.9, 1.05)
	thunk_sound.play()

## The title drifts with the mouse (the scenery handles its own parallax).
func _update_parallax(delta: float) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	var mouse: Vector2 = get_viewport().get_mouse_position() / viewport_size - Vector2(0.5, 0.5)
	mouse = mouse.clamp(Vector2(-0.5, -0.5), Vector2(0.5, 0.5))
	var weight: float = 1.0 - exp(-3.0 * delta)
	_title_drift = _title_drift.lerp(mouse * parallax_strength * 0.35, weight)
	title_root.position = _title_drift + Vector2(0.0, sin(_time * 1.3) * 5.0)

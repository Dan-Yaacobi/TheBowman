class_name SpiritInteractedState extends NPCInteractedState
## The world spirit's Interacted state. Switches between the options menu and dialogue:
## pick an option → its dialogue plays (Interact advances) → back to the menu.
## Closes when the player walks away, presses Exit, or no turn-ins are left after an option.

enum Mode { MENU, DIALOGUE }

var _mode: Mode = Mode.MENU
var _spirit: WorldSpirit
## False once the state exits, so an option still awaiting dialogue knows to stop.
var _open: bool = false

func init() -> void:
	_spirit = npc as WorldSpirit

func Enter() -> void:
	_open = true
	_spirit.menu.option_chosen.connect(_on_menu_option_chosen)
	_show_menu()

func Exit() -> void:
	_open = false
	_spirit.menu.option_chosen.disconnect(_on_menu_option_chosen)
	_spirit.menu.close()
	# Closing the chat box also ends any dialogue an option is awaiting.
	super()

func HandleInput(event: InputEvent) -> NPCState:
	if event.is_action_pressed("Exit"):
		return idle
	if not event.is_action_pressed("Interact"):
		return null
	match _mode:
		Mode.MENU:
			_spirit.menu.choose_focused()
		Mode.DIALOGUE:
			if npc.chat_box.is_last_line and not npc.chat_box._is_typing:
				npc.chat_box.finish_lines()
			else:
				npc.chat_box.advance()
	return null

func _show_menu() -> void:
	_mode = Mode.MENU
	npc.chat_box.show_prompt(npc.data.npc_name, _spirit.greeting_line)
	_spirit.menu.open(_spirit.get_entries())

func _on_menu_option_chosen(entry: SpiritMenuEntry) -> void:
	if _mode != Mode.MENU:
		return
	_mode = Mode.DIALOGUE
	_spirit.menu.close()
	await entry.option.run(entry, _spirit)
	if not _open or not is_inside_tree():
		return
	if _spirit.has_turn_in():
		_show_menu()
	else:
		state_machine.ChangeState(idle)

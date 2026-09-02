class_name NPCGoneState extends NPCState

@onready var idle: NPCIdleState = $"../Idle"
@onready var keyboard_press_helper: KeyBoardHelper = $"../../KeyboardPressHelper"

func init() -> void:
	pass

func Enter() -> void:
	keyboard_press_helper.hide()
	if npc.data.disappears:
		npc.disappear.emit()
		var tween: Tween = npc.create_tween()
		tween.tween_property(npc, "modulate:a", 0.0, 0.5)
		tween.finished.connect(npc.queue_free)
	else:
		npc.interaction_area.body_entered.disconnect(idle._on_body_entered)
		npc.interaction_area.body_exited.disconnect(idle._on_body_exited)
	npc.extra_gone_function()
		
func Exit() -> void:
	pass

func Process(_delta: float) -> NPCState:
	return null

func Physics(_delta: float) -> NPCState:
	return null

func HandleInput(_event: InputEvent) -> NPCState:
	return null

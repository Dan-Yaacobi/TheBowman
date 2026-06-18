class_name NPCGoneState extends NPCState

@onready var idle: NPCIdleState = $"../Idle"

func init() -> void:
	pass

func Enter() -> void:
	if npc.data.disappears:
		npc.disappear.emit()
		var tween: Tween = npc.create_tween()
		tween.tween_property(npc, "modulate:a", 0.0, 0.5)
		tween.finished.connect(npc.queue_free)
	else:
		idle.show_helper = false
		npc.interaction_area.body_entered.disconnect(idle._on_body_entered)
		npc.interaction_area.body_exited.disconnect(idle._on_body_exited)
func Exit() -> void:
	pass

func Process(_delta: float) -> NPCState:
	return null

func Physics(_delta: float) -> NPCState:
	return null

func HandleInput(_event: InputEvent) -> NPCState:
	return null

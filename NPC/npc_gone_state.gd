class_name NPCGoneState extends NPCState

func init() -> void:
	pass

func Enter() -> void:
	npc.disappear.emit()
	var tween: Tween = npc.create_tween()
	tween.tween_property(npc, "modulate:a", 0.0, 0.5)
	tween.finished.connect(npc.queue_free)

func Exit() -> void:
	pass

func Process(_delta: float) -> NPCState:
	return null

func Physics(_delta: float) -> NPCState:
	return null

func HandleInput(_event: InputEvent) -> NPCState:
	return null

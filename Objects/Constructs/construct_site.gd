class_name ConstructSite extends Node2D
## A hub construct that has to be built before it works.
## Unbuilt: the construct shows as a faint ghost and is fully disabled.
## Built: the construct becomes solid and active. Saved through MetaProgress.

signal built

## Saved in the save file. Never rename once players have saves.
@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var cost: Dictionary[CustomVariables.items, int] = {}

@export var construct: CanvasItem
## The floating window (its own scene, as a child of this site).
@export var build_prompt: BuildPrompt
## Shows the build prompt while the player is inside it.
@export var proximity_area: Area2D

@export_group("Look")
@export var ghost_color: Color = Color(0.7, 0.85, 1.0, 0.35)
@export var build_duration: float = 0.6

var _player_near: bool = false

func _ready() -> void:
	build_prompt.setup(self)
	if MetaProgress.is_built(id):
		_set_built(false)
		return
	_set_ghost()
	proximity_area.body_entered.connect(_on_body_entered)
	proximity_area.body_exited.connect(_on_body_exited)

## Called by the build prompt's button. Returns true if it was built.
func try_build() -> bool:
	if not MetaProgress.build(id, cost, PlayerManager.player):
		return false
	_set_built(true)
	built.emit()
	return true

func can_afford() -> bool:
	return MetaProgress.can_pay(cost, PlayerManager.player.stats)

func _set_ghost() -> void:
	construct.modulate = ghost_color
	construct.process_mode = Node.PROCESS_MODE_DISABLED

func _set_built(animate: bool) -> void:
	construct.process_mode = Node.PROCESS_MODE_INHERIT
	if animate:
		build_prompt.close()
	else:
		build_prompt.hide()
	proximity_area.set_deferred(&"monitoring", false)
	if animate:
		var tween: Tween = create_tween()
		tween.tween_property(construct, "modulate", Color.WHITE, build_duration)
	else:
		construct.modulate = Color.WHITE

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		_player_near = true
		build_prompt.open()

func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_near = false
		build_prompt.close()

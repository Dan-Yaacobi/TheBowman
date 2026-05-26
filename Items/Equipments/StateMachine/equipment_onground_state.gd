class_name EquipmentOnGroundState extends EquipmentState

const BOB_SPEED = 2.0
const BOB_AMPLITUDE = 3.0

var _bob_time: float = 0.0

func init() -> void:
	pass

func Enter() -> void:
	equipment.sprite.rotation = 0.0
	equipment.freeze_body()
	equipment.is_landed = true
	equipment.interaction_area.monitoring = true
	equipment.interaction_area.connect("body_entered", _on_player_entered)
	_apply_glow()

func Exit() -> void:
	equipment.interaction_area.monitoring = false
	if equipment.interaction_area.is_connected("body_entered", _on_player_entered):
		equipment.interaction_area.disconnect("body_entered", _on_player_entered)
	_bob_time = 0.0

func Process(delta: float) -> EquipmentState:
	_bob_time += delta
	var bob_offset = sin(_bob_time * BOB_SPEED) * BOB_AMPLITUDE
	equipment.position.y += bob_offset * delta
	return null

func Physics(_delta: float) -> EquipmentState:
	return null

func _apply_glow() -> void:
	# apply glow shader or PointLight2D color to equipment.sprite
	# color should be drawn from equipment.data.get_glow_color()
	pass

func _on_player_entered(body: Node2D) -> void:
	if body is Player:
		state_machine.ChangeState(state_machine.states[2]) # EquipmentInteractedState

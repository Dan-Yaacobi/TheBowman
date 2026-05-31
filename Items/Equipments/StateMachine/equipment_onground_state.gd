class_name EquipmentOnGroundState extends EquipmentState
@onready var interacted: EquipmentInteractedState = $"../Interacted"
const BOB_SPEED = 2.0
const BOB_AMPLITUDE = 3.0
var _bob_time: float = 0.0
var snap_position: Vector2

func init() -> void:
	EventBus.equipment_interaction_exit.connect(_on_any_interaction_closed)

func Enter() -> void:
	snap_position = equipment.position
	equipment.sprite.rotation = 0.0
	equipment.freeze_body()
	equipment.interaction_area.monitoring = true
	equipment.interaction_area.connect("body_entered", _on_player_entered)
	_apply_glow()

func Exit() -> void:
	equipment.position = snap_position
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
	pass

func _on_player_entered(body: Node2D) -> void:
	if body is Player:
		_try_interact(body)

func _on_any_interaction_closed(_equip: Equipment) -> void:
	if state_machine.curr_state != self:
		return
	_try_interact(PlayerManager.player)

func _try_interact(player: Player) -> void:
	if not player.equipment_interacted and equipment.interaction_area.overlaps_body(player):
		player.equipment_interacted = equipment
		state_machine.ChangeState(interacted)

func HandleInput(_event: InputEvent) -> EquipmentState:
	return null

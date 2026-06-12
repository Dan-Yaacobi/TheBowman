class_name EquipmentDroppedState extends EquipmentState
@onready var on_ground: EquipmentOnGroundState = $"../OnGround"
var rotation_speed: float = 5.0

func init() -> void:
	pass

func Enter() -> void:
	equipment.sprite.scale *= equipment.data.dropped_scale
	equipment.lock_rotation = true
	equipment.gravity_scale = 1.0
	equipment.freeze = false
	equipment.ground_detection_area.monitoring = false
	equipment.call_deferred("apply_drop_impulse")

func Exit() -> void:
	equipment.ground_detection_area.monitoring = false

func Process(_delta: float) -> EquipmentState:
	return null

func Physics(delta: float) -> EquipmentState:
	equipment.sprite.rotation += rotation_speed * delta
	equipment.linear_velocity = equipment.linear_velocity.clamp(
		Vector2(-200, -200), 
		Vector2(200, 200)
	)
	if not equipment.ground_detection_area.monitoring and equipment.linear_velocity.y > 0:
		equipment.ground_detection_area.monitoring = true
	if equipment.is_landed:
		return on_ground
	return null

func HandleInput(_event: InputEvent) -> EquipmentState:
	return null

class_name Equipment extends RigidBody2D

@onready var state_machine: EquipmentStateMachine = $EquipmentStateMachine
@onready var ground_ray: RayCast2D = $GroundRay
@onready var interaction_area: Area2D = $InteractionArea
@onready var sprite: Sprite2D = $Sprite2D
@onready var ground_detection_area: Area2D = $GroundDetectionArea
@onready var un_equipped_state: EquipmentUnEquippedState = $EquipmentStateMachine/UnEquipped

var data: EquipmentData
var is_landed: bool = false

func _ready() -> void:
	lock_rotation = true
	gravity_scale = 1.0
	freeze = false
	ground_detection_area.connect("body_shape_entered", _on_ground_detected)
	state_machine.Initialize(self)
	EventBus.destory_view_item.connect(clear_item)
	set_data()
	
func apply_drop_impulse() -> void:
	apply_impulse(Vector2(randf_range(-30, 30), -400))
	
func equip_to_player() -> void:
	PlayerManager.player.set_equipped_in_slot(data.slot, data)
	PlayerManager.player.equip_item(self, data.slot)
	
func unequip_from_player() -> void:
	data.unequip(PlayerManager.player.stats)
	if data.ability:
		PlayerManager.player.unregister_ability(data.ability)
	
func freeze_body() -> void:
	freeze = true
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	lock_rotation = true
	gravity_scale = 0.0

func get_equipped_item_in_same_slot() -> EquipmentData:
	# return the player's currently equipped item in the same slot as this equipment
	# e.g. return PlayerManager.player.equipment_handler.get_slot(data.slot)
	# return null if slot is empty
	return PlayerManager.player.stats.bow

func _on_ground_detected(_var1,_var2,_var3,_var4) -> void:
	if not is_landed and _var2 is Island:
		is_landed = true

func clear_item(_equip: Equipment) -> void:
	if self == _equip:
		queue_free()

func set_data() -> void:
	if data and sprite:
		sprite.texture = data.texture

func become_unequipped() -> void:
	state_machine.ChangeState(un_equipped_state)

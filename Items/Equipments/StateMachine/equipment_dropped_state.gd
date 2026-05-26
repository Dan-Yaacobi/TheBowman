class_name EquipmentDroppedState extends EquipmentState
var rotation_speed: float = 5.0

func init() -> void:
	pass

func Enter() -> void:
	equipment.lock_rotation = false
	equipment.gravity_scale = 1.0
	equipment.freeze = false
	equipment.apply_drop_impulse()
	_attempt_ground_detection()

func Exit() -> void:
	pass

func Process(_delta: float) -> EquipmentState:
	return null

func Physics(delta: float) -> EquipmentState:
	equipment.sprite.rotation += rotation_speed * delta
	if equipment.is_landed:
		return state_machine.states[1]
	return null

func _attempt_ground_detection() -> void:
	equipment.ground_ray.force_raycast_update()
	if equipment.ground_ray.is_colliding():
		# ray found ground, physics will land it naturally
		pass
	else:
		# no ground below, activate magnet area to find nearby island
		equipment.magnet_area.monitoring = true
		equipment.magnet_area.connect("area_entered", _on_magnet_area_detected)

func _on_magnet_area_detected(area: Area2D) -> void:
	# get the nearest point on the detected island and apply a continuous
	# force toward it each physics frame until landed
	equipment.magnet_area.monitoring = false
	var target_position = area.global_position
	var direction = (target_position - equipment.global_position).normalized()
	equipment.linear_velocity = direction * 300.0

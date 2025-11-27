class_name Island extends StaticBody2D

func disable() -> void:
	set_collision_layer_value(5,false)
	set_collision_mask_value(1,false)

func enable() -> void:
	set_collision_layer_value(5,true)
	set_collision_mask_value(1,true)
	pass

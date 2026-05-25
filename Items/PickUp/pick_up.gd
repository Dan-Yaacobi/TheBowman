class_name PickUp extends Node2D

@export var data: PickUpData

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		picked_up(body)

func picked_up(player: Player) -> void:
	pass

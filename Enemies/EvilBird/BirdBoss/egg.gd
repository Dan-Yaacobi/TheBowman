class_name Egg extends RigidBody2D

signal cracked(_position: Vector2)
@onready var hit_box: HitBox = $HitBox

func _ready() -> void:
	hit_box.Damaged.connect(destroyed)
	
func crack_egg() -> void:
	cracked.emit(global_position)
	queue_free()

func _on_grounddetector_body_shape_entered(_body_rid: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if _body is Island:
		crack_egg()

func destroyed(_hurt_box: HurtBox) -> void:
	queue_free()

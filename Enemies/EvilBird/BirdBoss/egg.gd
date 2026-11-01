class_name Egg extends RigidBody2D

signal cracked(_position: Vector2)

const SHATTER_ANIMATION: StringName = &"Shatter"

@onready var hit_box: HitBox = $HitBox
@onready var ground_detector: Area2D = $Grounddetector
@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer

var _is_destroyed: bool = false

func _ready() -> void:
	hit_box.Damaged.connect(destroyed)
	animation_player.animation_finished.connect(_on_animation_player_animation_finished)

func crack_egg() -> void:
	if _is_destroyed:
		return
	cracked.emit(global_position)
	queue_free()

func _on_grounddetector_body_shape_entered(_body_rid: RID, _body: Node2D, _body_shape_index: int, _local_shape_index: int) -> void:
	if _body is Island:
		crack_egg()

func destroyed(_hurt_box: HurtBox, _var2, _var3) -> void:
	if _is_destroyed:
		return
	_is_destroyed = true
	# Stop it from falling, being hit again or hatching while the shell breaks apart
	set_deferred("freeze", true)
	linear_velocity = Vector2.ZERO
	hit_box.set_deferred("monitorable", false)
	hit_box.set_deferred("monitoring", false)
	ground_detector.set_deferred("monitoring", false)
	animation_player.play(SHATTER_ANIMATION)

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == SHATTER_ANIMATION:
		queue_free()

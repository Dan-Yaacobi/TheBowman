class_name GameObject extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: HitBox = $HitBox
@onready var placement_marker: Marker2D = $PlacementMarker

@export var data: ObjectData

var got_hit: bool = false

func _ready() -> void:
	if not data.interactable:
		hit_box.monitorable = false
		
	hit_box.Damaged.connect(break_item)
	
func break_item(_hurt_box: HurtBox) -> void:
	if data.interactable and not got_hit:
		got_hit = true
		sprite.material = sprite.material.duplicate()
		var tween: Tween = create_tween()
		tween.tween_method(
			func(v: float) -> void: sprite.material.set_shader_parameter("progress", v),
			0.0, 1.0, 0.4
		).set_trans(Tween.TRANS_LINEAR)
		await tween.finished
		queue_free()
	

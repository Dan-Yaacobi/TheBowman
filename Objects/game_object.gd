class_name GameObject extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: HitBox = $HitBox
@onready var placement_marker: Marker2D = $PlacementMarker

@export var data: ObjectData
@export var avg_coin_drop: int = 1
@export_range(0.0,100.0,0.1,"suffix:%") var potion_drop_chance: float = 20.0
@export_range(0.0,100.0,0.1,"suffix:%") var equip_drop_chance: float = 0.0

var got_hit: bool = false

func _ready() -> void:
	if not data.interactable:
		hit_box.monitorable = false
		
	hit_box.Damaged.connect(break_item)
	
func break_item(_hurt_box: HurtBox) -> void:
	if data.interactable and not got_hit:
		got_hit = true
		EventBus.camera_shake.emit(2.0,25.0)
		sprite.material = sprite.material.duplicate()
		var tween: Tween = create_tween()
		tween.tween_method(
			func(v: float) -> void: sprite.material.set_shader_parameter("progress", v),
			0.0, 1.0, 0.4
		).set_trans(Tween.TRANS_LINEAR)
		await tween.finished
		drop_items()
		queue_free()

func drop_items(_equip_skew: float = 0) -> void:
	drop_coins()
	drop_equip(_equip_skew)
	drop_potion()
	
func drop_coins() -> void:
	EventBus.drop_coins.emit(global_position,avg_coin_drop)
	
func drop_potion() -> void:
	EventBus.drop_potion.emit(global_position, potion_drop_chance)

func drop_equip(_equip_skew: float = 0) -> void:
	EventBus.try_drop.emit(global_position, equip_drop_chance, _equip_skew)
	

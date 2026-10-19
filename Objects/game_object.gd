class_name GameObject extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_box: HitBox = $HitBox
@onready var placement_marker: Marker2D = $PlacementMarker
@export var data: ObjectData
@export var avg_coin_drop: int = 0
@export var item_drop: CustomVariables.items
@export_range(0.0,100.0,0.1,"suffix:%") var item_drop_chance

@export_category("Textures")
@export var use_fixed_frame: bool = false
@export var fixed_frame_index: int = 0
@export var textures: Array[TextureData]

var got_hit: bool = false

func _ready() -> void:
	if not data.interactable:
		hit_box.monitorable = false
		
	hit_box.Damaged.connect(break_item)
	setup(get_rift_type())
	
func get_rift_type() -> Rift.Type:
	var lvl: int = PlayerManager.player.stats.rift_level
	if lvl < 1 or CustomVariables.RIFTS_PER_TYPE <= 0:
		return Rift.Type.DIRT

	@warning_ignore("integer_division")
	var index: int = (lvl - 1) / CustomVariables.RIFTS_PER_TYPE
	
	if index >= Rift.Type.size():
		return Rift.Type.DIRT
	return index as Rift.Type

func break_item(_hurt_box: HurtBox,_raw_damage: int = 0, _result: DamageResult = null) -> void:
	if data.interactable and not got_hit:
		EventBus.object_destroyed_sound.emit()
		got_hit = true
		EventBus.camera_shake.emit(2.0,25.0)
		if sprite.material:
			sprite.material = sprite.material.duplicate()
			var tween: Tween = create_tween()
			tween.tween_method(
				func(v: float) -> void: sprite.material.set_shader_parameter("progress", v),
				0.0, 1.0, 0.4
			).set_trans(Tween.TRANS_LINEAR)
			await tween.finished
		drop_items()
		queue_free()

func drop_items() -> void:
	var amount: int = 1
	if item_drop == CustomVariables.items.COIN and avg_coin_drop > 0:
		amount = avg_coin_drop
	EventBus.drop_item.emit(item_drop, global_position, item_drop_chance,amount)

func setup(rift_type: Rift.Type) -> void:
	var matching: TextureData = _get_texture_data_for_type(rift_type)
	if matching == null:
		return
	var new_sprite: AtlasTexture
	if use_fixed_frame:
		new_sprite = matching.get_sprite_at(fixed_frame_index)
	else:
		new_sprite = matching.get_random_sprite()
	if new_sprite != null:
		sprite.texture = new_sprite
		
func _get_texture_data_for_type(rift_type: Rift.Type) -> TextureData:
	for data: TextureData in textures:
		if data.type == rift_type:
			return data
	return null

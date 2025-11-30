class_name ShopWeaponData extends Resource

@export var texture: Texture
@export var name: String
@export var name_color: Color
@export var name_shadow_color: Color
@export var price: int
@export var special_ability: String
@export var block_coordinate: Vector2
@export var bought: bool
@export var button_click_action: ButtonAction
@export var weapon_scene: PackedScene

func get_damage() -> int:
	var val = 0
	if weapon_scene != null:
		var temp: Weapon = weapon_scene.instantiate()
		val = temp.weapon_data.base_damage
		temp.queue_free()
	return val
	
func get_arrows_per_shot() -> int:
	var val = 0
	if weapon_scene != null:
		var temp: Weapon = weapon_scene.instantiate()
		val = temp.weapon_data.shots
		temp.queue_free()
	return val

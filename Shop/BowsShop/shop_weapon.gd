class_name ShopWeapon extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var name_label: Label = $BowName
@onready var label: Label = $Label
@onready var buy_button: MainButton = $ButtonShootClick
@onready var new_bow_buy_effect: CPUParticles2D = $NewBowBuyEffect
@onready var special_ability_label: Label = $SpecialAbilityLabel
@onready var damage_label: Label = $WeaponDamage
@onready var arrows_per_shot: Label = $ArrowsPerShot

@export var data: ShopWeaponData

var player: Player
 
func set_shop_weapon() -> void:
	if data != null:
		sprite.texture = data.texture
		name_label.text = data.name
		name_label.add_theme_color_override("font_color", data.name_color)
		name_label.add_theme_color_override("font_shadow_color", data.name_shadow_color)
		label.text = "Price: " + str(data.price)
		update_damage_label(data.get_damage())
		update_arrows_per_shot_label(data.get_arrows_per_shot())
	buy_button.button_data.button_action = data.button_click_action
	if not buy_button.clicked.is_connected(change_to_switch_button):
		buy_button.clicked.connect(change_to_switch_button)
	#buy_button.tooltip_text = "Special Ability: " + data.special_ability
	special_ability_label.text = "Special Ability: " + data.special_ability
	special_ability_label.add_theme_color_override("font_color", data.name_color)
	special_ability_label.add_theme_color_override("font_shadow_color", data.name_color.darkened(0.2))
	special_ability_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
func change_button_color(_can_buy: bool) -> void:
	if _can_buy:
		buy_button.add_theme_color_override("font_color",Color.WHITE)
		buy_button.add_theme_color_override("font_focus_color",Color.WHITE)
		buy_button.add_theme_color_override("font_pressed_color",Color.WHITE)
		buy_button.add_theme_color_override("font_hover_color",Color.WHITE)
	else:
		buy_button.add_theme_color_override("font_color",Color.RED)
		buy_button.add_theme_color_override("font_focus_color",Color.RED)
		buy_button.add_theme_color_override("font_pressed_color",Color.DARK_RED)
		buy_button.add_theme_color_override("font_hover_color",Color.INDIAN_RED)

func change_to_switch_button() -> void:
	if buy_button.text != "Switch":
		new_bow_buy_effect.global_position = player.global_position
		new_bow_buy_effect.emitting = true
	buy_button.text = "Switch"
	label.visible = false

func update_damage_label(amount: int) -> void:
	damage_label.add_theme_color_override("font_color", data.name_color)
	damage_label.add_theme_color_override("font_shadow_color", data.name_shadow_color)
	damage_label.text = "Damage: " + str(amount)
	pass

func update_arrows_per_shot_label(amount: int) -> void:
	arrows_per_shot.add_theme_color_override("font_color", data.name_color)
	arrows_per_shot.add_theme_color_override("font_shadow_color", data.name_shadow_color)
	arrows_per_shot.text = "Arrows Per Shot: " + str(amount)
	pass

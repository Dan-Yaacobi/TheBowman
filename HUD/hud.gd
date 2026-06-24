class_name HUD extends CanvasLayer

@onready var level_stats: Label = $Control/LevelStats
@onready var special_ability_cd: Sprite2D = $Control/SpecialAbilityCD
@onready var current_money: CurrentMoney = $Control/CurrentMoney
@onready var coin_animation: AnimationPlayer = $Control/Coin/CoinAnimation
@onready var rift_level_label: Label = $RiftLevel
@onready var damaged_flash: ColorRect = $DamagedFlash
@onready var heal_flash: ColorRect = $HealFlash
@onready var health_bar: Control = $Control/HealthBar
@onready var boss_health_bar: Control = $Control/BossHealthBar
@onready var interaction_ui: EquipmentInteractionUI = $InteractionUi
@onready var equipment_menu: EquipmentMenu = $EquipmentMenu
@onready var pause_menu: PauseMenu = $PauseMenu

var current_view_item: Equipment
var flash_tween: Tween

func _ready() -> void:
	interaction_ui.visible = false
	PlayerManager.player.money_changed.connect(update_money)
	coin_animation.play("Rotate")
	EventBus.equipment_interaction_enter.connect(show_equip_interaction_ui)
	EventBus.equipment_interaction_exit.connect(hide_equip_interaction_ui)
	interaction_ui.equip_new_item.connect(equip_item)
	interaction_ui.destory_new_item.connect(destory_item)
	EventBus.entered_rift.connect(show_rift_label)
	rift_level_label.modulate.a = 0
	EventBus.damaged_flash.connect(apply_damage_flash)
	EventBus.healed_flash.connect(apply_heal_flash)
	damaged_flash.modulate.a = 0.0
	heal_flash.modulate.a = 0.0
	boss_health_bar.hide()
	EventBus.request_boss_health_bar.connect(send_boss_health_bar)
	EventBus.hide_boss_health_bar.connect(hide_boss_health_bar)
	pause_menu.setup(equipment_menu)


func apply_damage_flash() -> void:
	if flash_tween:
		flash_tween.kill()
	damaged_flash.modulate = Color(1, 0, 0, 0.3)
	flash_tween = create_tween()
	flash_tween.tween_property(damaged_flash, "modulate", Color(1, 0, 0, 0.0), 0.3)


func apply_heal_flash() -> void:
	if flash_tween:
		flash_tween.kill()
	heal_flash.modulate = Color(0.0, 1.0, 0.0, 0.3)
	flash_tween = create_tween()
	flash_tween.tween_property(heal_flash, "modulate", Color(1, 0, 0, 0.0), 0.3)


func get_health_bar() -> HealthBar:
	return health_bar.get_child(1)


func send_boss_health_bar() -> void:
	EventBus.boss_health_bar.emit(boss_health_bar.get_child(1))
	boss_health_bar.show()


func hide_boss_health_bar() -> void:
	boss_health_bar.hide()


func get_special_ability_cd() -> Sprite2D:
	return special_ability_cd


func update_money(amount: Variant) -> void:
	current_money.update_current_money(amount)


func show_equip_interaction_ui(equipment: Equipment) -> void:
	var screen_pos: Vector2 = equipment.get_viewport().get_canvas_transform() * equipment.position
	interaction_ui.global_position = screen_pos + Vector2(0, -50)
	interaction_ui.visible = true
	interaction_ui.set_items(equipment)
	current_view_item = equipment


func hide_equip_interaction_ui(_equip: Equipment) -> void:
	interaction_ui.visible = false
	current_view_item = null


func equip_item() -> void:
	if current_view_item:
		EventBus.equip_item.emit(current_view_item)


func destory_item() -> void:
	if current_view_item:
		EventBus.destory_view_item.emit(current_view_item)


func show_rift_label() -> void:
	rift_level_label.text = "Rift Level: " + str(PlayerManager.player.stats.rift_level)
	rift_level_label.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_property(rift_level_label, "modulate:a", 0.0, 1.5).set_delay(1)


func _on_feedback_pressed() -> void:
	pause_menu._set_state(PauseMenu.PauseState.MAIN)
	OS.shell_open("https://game-feedback-app.vercel.app/")

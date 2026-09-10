extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

signal tutorial_done
signal dash_preformed

signal start_shooting
signal arrow(_arrow: Arrow)

signal damaged_flash
signal healed_flash

signal apply_player_knockback(direction: Vector2, force: float, continous: bool)
signal invisible_hands(yes: bool)

signal changed_scene(new_scene: GameWorlds.worlds)

signal change_camera_focus(target: Vector2)
signal reset_camera_focus
signal camera_shake(_strength: float, _fade: float)

signal arrow_hit_sound
signal arrow_shot_sound
signal coin_drop_sound
signal button_click_sound
signal arrow_hit_wall_sound
signal string_pull_sound(pitch: float)
signal string_pull_stop
signal arrow_release_sound(pitch: float)
signal object_destroyed_sound
signal enemy_died_sound(_audio: AudioStream)
signal sword_slash_sound()

signal dealt_bleed_damage(_amount)

signal leeched(amount: int, position: Vector2)

signal exit_ui

signal open_upgrades_window(tier: int)

signal enemy_summoned(enemy: Enemy)
signal enemy_died(enemy: Enemy)

signal entered_rift
signal world_ready

signal summon_effect(effect: Node2D)

signal finished_loading()

signal add_player_buff(_buff: Buff)

signal player_buff_ended(_buff_id: int)

signal add_arrow_effect(_effect: Effect)

#signals that you went to the next rift level
signal entered_rift_portal

signal try_drop(position: Vector2, _chance: float)
signal drop_coins(position: Vector2, _amount: int)
signal drop_potion(position: Vector2, _chance: float)
signal drop_specific_item(item: EquipmentData, position: Vector2)

signal equipment_dropped(equip_data: EquipmentData, position: Vector2, _existing_equipment: Equipment)

signal equipment_interaction_enter(equip: Equipment)
signal equipment_interaction_exit(equip: Equipment)

signal equip_item(equip: Equipment)
signal destory_view_item(equip: Equipment)

signal arrow_enemy_hit(_perfect: bool, _arrow: Arrow, _target: Enemy)
signal arrow_missed

signal boss_health_bar(_bar: HealthBar)
signal request_boss_health_bar
signal hide_boss_health_bar

signal in_main_menu

signal fill_gauge(_amount: int)
signal request_gauge(_only_full: bool)
signal use_gauge(_amount: int)
signal setup_gauge(_max_value: int, _texture: Texture, _tint: Color)
signal disable_gauge()

signal sword_hit(_enemy: Enemy)

signal enemy_stunned(_enemy: Enemy)
signal enemy_frostbitten_hit(_enemy: Enemy)

signal player_died(_death_screen: bool)

signal active_ability_equipped(ability: ActiveAbility)
signal active_ability_used(cooldown: float)
signal active_ability_ready()
signal show_active_ability_picker(pool: Array[ActiveAbility])
signal active_ability_cleared

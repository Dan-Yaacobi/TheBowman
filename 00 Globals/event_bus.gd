extends Node
signal start_shooting
signal arrow(_arrow: Arrow)

signal out_of_mana

signal invisible_hands(yes: bool)

signal changed_scene(new_scene: GameWorlds.worlds)

signal change_camera_focus(target: Vector2)
signal reset_camera_focus
signal camera_shake(_strength: float, _fade: float)

signal arrow_hit_sound
signal arrow_shot_sound

signal leeched(amount: int, position: Vector2)

signal exit_ui

signal open_upgrades_window(tier: int)

signal enemy_summoned(enemy: Enemy)
signal enemy_died(enemy: Enemy)

signal entered_rift

signal summon_effect(effect: Node2D)

signal finished_loading()

signal add_player_buff(_buff: Buff)

signal player_buff_ended(_buff_id: int)

signal add_arrow_effect(_effect: Effect)

signal arrow_hit_enemy(_target: Enemy)

#signals that you went to the next rift level
signal entered_rift_portal

signal try_drop(position: Vector2, _chance: float)
signal drop_coins(position: Vector2, _amount: int)
signal drop_potion(position: Vector2, _chance: float)

signal equipment_dropped(equip_data: EquipmentData, position: Vector2, _existing_equipment: Equipment)

signal equipment_interaction_enter(equip: Equipment)
signal equipment_interaction_exit(equip: Equipment)

signal equip_item(equip: Equipment)
signal destory_view_item(equip: Equipment)

signal arrow_enemy_hit(_perfect: bool)
signal arrow_missed

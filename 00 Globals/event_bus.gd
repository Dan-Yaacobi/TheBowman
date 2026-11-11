extends Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

signal dash_preformed
signal dash_ended
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
## Seconds the draw takes at the current pull speed; the draw sound is stretched to match.
signal string_pull_sound(draw_duration: float)
signal string_pull_stop
signal arrow_release_sound(pitch: float)
signal object_destroyed_sound
signal enemy_died_sound(_audio: AudioStream)
signal sword_slash_sound()
signal jump_sound
signal footstep_sound
signal portal_entered_sound
signal play_any(_audio: AudioStream, pich_min: float, pitch_max: float, volume: float)

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

signal try_drop(position: Vector2, _chance: float, forced_rarity: int)
signal drop_item(item: CustomVariables.items, position: Vector2, _chance: float, _amount: int)
signal drop_coins(position: Vector2, _amount: int)
signal drop_potion(position: Vector2, _chance: float)
signal drop_specific_item(item: EquipmentData, position: Vector2, forced_rarity: int)
signal drop_essence(position: Vector2, chance: float)

signal equipment_dropped(equip_data: EquipmentData, position: Vector2, _existing_equipment: Equipment)

signal equipment_interaction_enter(equip: Equipment)
signal equipment_interaction_exit(equip: Equipment)

signal equip_item(equip: Equipment)
signal destory_view_item(equip: Equipment)

signal arrow_enemy_hit(_perfect: bool, _arrow: Arrow, _target: Enemy)
signal arrow_missed

signal hide_boss_health_bar
signal boss_fight_started(boss: Boss)
signal in_main_menu
signal boss_portal_entered
signal fill_gauge(_amount: int)
signal request_gauge(_only_full: bool)
signal use_gauge(_amount: int)
signal setup_gauge(_max_value: int, _texture: Texture, _tint: Color)
signal disable_gauge
signal charge_gauge()
signal gauge_charge_used
signal sword_hit(_target: Node2D)

signal enemy_stunned(_enemy: Enemy)
signal enemy_frostbitten_hit(_enemy: Enemy)

signal player_died(_death_screen: bool)
## The final boss was killed. Ends the run as a win (nothing emits this yet).
signal run_won
## A run ended (death, win, return to hub or quit). Summary built by RunTracker.
signal run_ended(summary: Dictionary)

signal active_ability_equipped(ability: ActiveAbility)
signal active_ability_used(cooldown: float)
signal active_ability_ready()
signal show_active_ability_picker(pool: Array[ActiveAbility])
signal active_ability_cleared
signal reduce_active_ability_cooldown(_amount: float)

signal rift_respawn_position(position: Vector2)
signal respawn_player
signal event_enter_requested(event_scene: PackedScene, return_position: Vector2)
signal event_exit_requested()
signal event_exited()
## After the player is placed in the event scene and the event has started.
signal event_entered()

signal open_upgrade_menu
signal upgrade_menu_closed
signal close_upgrade_menu
signal open_craft_menu(drop_position: Vector2)
signal craft_menu_closed
signal close_craft_menu

## The comparison window opened for this item. Disenchanting counts it toward the run tally.
signal equipment_inspected(data: EquipmentData)
## Items in the run tally (found, not yet disenchanted).
signal found_items_changed(count: int)
## Lifetime disenchanted items reached a milestone (again, for a repeating one).
## level = milestones reached so far, counting every repeat.
signal disenchant_milestone_reached(level: int, milestone: DisenchantMilestone)
## Cosmetic: resource icons fly from a world position to their HUD counter over duration seconds.
## The resource itself is paid separately, when they land.
signal resource_flight_started(item: CustomVariables.items, amount: int, from_world: Vector2, duration: float)

signal activate_gauge

signal relocate_player(_position: Vector2)

signal poison_damage_dealt

signal change_sky_color(sky_colors: SkyColors)

signal color_level_changed(color: CustomVariables.ItemColor, level: int)
signal color_scroll_collected

signal lore_item_found(item: LoreItemData)
## The player interacted with a lore item in the world; the HUD shows it with a pick up button.
signal lore_item_inspected(item: LoreItemData)
## The player chose to pick up the inspected lore item.
signal lore_item_pickup_confirmed(item: LoreItemData)
## Something outside the HUD (the spirit) asks for the artifact journal.
signal artifact_journal_requested
## The journal opened by artifact_journal_requested was closed.
signal artifact_journal_closed
## The spirit offers boons for the next run; the HUD shows the pick-1 window.
signal boon_picker_requested(offers: Array[SpiritBoon])
## The boon picker closed (a boon was picked).
signal boon_picker_closed

# --- Run tally (death screen) ---
## A resource pickup was added to the player's stash.
signal resource_collected(item: CustomVariables.items, amount: int)
## A breakable world object (crate, vase...) was destroyed.
signal object_destroyed(object: GameObject)
signal chest_opened(chest: Chest)
signal schematic_found
## Fired once per island, the first time the player stands on it.
signal island_stepped_on(island: Island)
## An event with a win/lose outcome ended (challenge shrine, golden apple, boss event...).
signal rift_event_finished(event: Event, success: bool)

# --- Run tracker (analytics) ---
## The player released a drawn arrow. power is the pull (1.0 = perfect).
signal arrow_released(power: float)
## The player took damage. source is the hurt box that hit, or null for damage over time.
signal player_damaged(amount: int, source: Node)
## The player was healed by this much (actual HP gained).
signal player_healed(amount: int)
## A potion was picked up and drunk.
signal potion_used(heal_amount: int)
## The player fell off the world. heart_lost is false for free falls and safe areas.
signal player_fell(heart_lost: bool)
## The player lost a heart container (falls, sacrifices).
signal player_heart_lost
## An enemy took damage from any source, DoT included.
signal enemy_damaged(enemy: Enemy, amount: int)

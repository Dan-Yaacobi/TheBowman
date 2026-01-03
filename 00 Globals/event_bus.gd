extends Node

signal start_shooting
signal arrow(_arrow: Arrow)

signal out_of_mana

signal invisible_hands(yes: bool)

signal changed_scene(new_scene: String)

signal change_camera_focus(target: Vector2)
signal reset_camera_focus

signal arrow_hit_sound
signal arrow_shot_sound

signal leeched(amount: int, position: Vector2)

signal exit_ui

signal open_upgrades_window(tier: int)

signal enemy_summoned(enemy: Enemy)
signal enemy_died(enemy: Enemy)

signal entered_rift

signal summon_effect(effect: Node2D)

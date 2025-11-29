extends Node

signal start_shooting
signal arrow(_arrow: Arrow)

signal out_of_mana

signal invisible_hands(yes: bool)

signal changed_scene(new_scene: String)

signal change_camera_focus(target: Vector2)
signal reset_camera_focus

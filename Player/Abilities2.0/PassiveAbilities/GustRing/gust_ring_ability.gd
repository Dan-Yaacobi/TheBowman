class_name GustRingAbility extends PlayerAbility
## Every jump, double jump included, releases a gust that pushes nearby enemies away.

@export var radius: float = 60.0
@export var force: float = 300.0

const GUST_COLOR: Color = Color(0.85, 0.95, 1.0)

func on_equipped() -> void:
	var jump_action: JumpAction = PlayerManager.player.jump_action
	if not jump_action.jumped.is_connected(_on_jumped):
		jump_action.jumped.connect(_on_jumped)

func on_unequipped() -> void:
	var jump_action: JumpAction = PlayerManager.player.jump_action
	if jump_action.jumped.is_connected(_on_jumped):
		jump_action.jumped.disconnect(_on_jumped)

func _on_jumped() -> void:
	var player: Player = PlayerManager.player
	PushWave.burst(player.get_world_2d(), player.global_position + Vector2(0, 6), radius, force * power(), 0, GUST_COLOR, 0.1)

func get_tooltip() -> String:
	return "Every jump releases a gust that pushes enemies away"

func get_tooltip_color() -> Color:
	return GUST_COLOR

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

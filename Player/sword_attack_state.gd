class_name SwordAttackState extends State

@onready var idle: PlayerIdleState = $"../Idle"

var finished: bool = false
var base_sword_scale: Vector2

func init() -> void:
	player.body.animation_player.animation_finished.connect(_on_body_animation_finished)
	player.body.slash_hurt_box.monitoring = false
	base_sword_scale = player.body.sword.scale

func Enter() -> void:
	finished = false
	player.disable_jump()
	player.show_hands(false)
	player.body.update_animation("Swing")
	var hurt_box: HurtBox = player.body.slash_hurt_box
	for ability in player.get_abilities(PlayerAbility.TriggerType.BEFORE_HIT):
		hurt_box.add_before_effect(ability.activate_ability)
	for ability in player.get_abilities(PlayerAbility.TriggerType.AFTER_HIT):
		hurt_box.add_after_effect(ability.activate_ability)
	hurt_box.base_damage = floor(player.stats.sword_damage.value())
	player.body.sword.scale = base_sword_scale * player.get_sword_size()
	player.apply_knockback(player.aim_direction, 75)
	EventBus.sword_slash_sound.emit()
	player.body.slash_animation_player.play("SlashEffect")
	player.can_swing += 1
	hurt_box.monitoring = true

func Exit() -> void:
	var hurt_box: HurtBox = player.body.slash_hurt_box
	hurt_box.monitoring = false
	hurt_box.clear_effects()
	player.body.sword.scale = base_sword_scale
	player.show_hands(true)
	player.enable_jump()
	player.swing_cooldown.wait_time = player.get_sword_cd()
	player.swing_cooldown.start()
	player.body.sword_sprite.visible = false
	
func Process(_delta: float) -> State:
	if finished:
		return idle
	var deceleration: float = player.stats.ground_dec if player.is_on_floor() else player.stats.air_dec
	player.velocity.x = move_toward(player.velocity.x, 0, deceleration * _delta)
	return null

func Physics(_delta: float) -> State:
	return null

func HandleInput(_event: InputEvent) -> State:
	return null

func _on_body_animation_finished(anim_name: StringName) -> void:
	if anim_name == "Swing":
		finished = true

class_name SwordAttackState extends State

## Swing damage lands within +/- this fraction of the sword damage stat.
const SWORD_HIT_SPREAD: float = 0.1

@onready var idle: PlayerIdleState = $"../Idle"

## Body animations played in order, one per swing. Each one keys the sword socket and the hit area.
@export var attack_animations: Array[StringName] = [&"Swing1", &"Swing2", &"Stab"]
## Seconds after a swing ends before the combo starts over from the first attack.
@export var combo_reset_time: float = 1.0

var finished: bool = false
var combo_index: int = 0
var last_attack_end_msec: int = -1000000
var current_animation: StringName = &""

func init() -> void:
	player.body.animation_player.animation_finished.connect(_on_body_animation_finished)

func Enter() -> void:
	finished = false
	player.disable_jump()
	player.show_hands(false)
	var since_last_attack: float = (Time.get_ticks_msec() - last_attack_end_msec) / 1000.0
	if since_last_attack > combo_reset_time:
		combo_index = 0
	current_animation = attack_animations[combo_index]
	combo_index = (combo_index + 1) % attack_animations.size()
	player.body.update_animation(current_animation)
	var hurt_box: HurtBox = player.body.slash_hurt_box
	# The quiver's debuff stays on arrows; the sword only applies it through Coated Blade.
	var quiver_ability: PlayerAbility = player.stats.arrow.ability if player.stats.arrow else null
	for ability in player.get_abilities(PlayerAbility.TriggerType.BEFORE_HIT):
		if ability == quiver_ability and ability.applies_quiver_debuff():
			continue
		hurt_box.add_before_effect(ability.activate_ability)
	for ability in player.get_abilities(PlayerAbility.TriggerType.AFTER_HIT):
		if ability == quiver_ability and ability.applies_quiver_debuff():
			continue
		hurt_box.add_after_effect(ability.activate_ability)
	# Same +/-10% spread as arrow hits, rolled per swing.
	hurt_box.base_damage = floor(player.stats.sword_damage.value() * randf_range(1.0 - SWORD_HIT_SPREAD, 1.0 + SWORD_HIT_SPREAD))
	player.body.sword.apply_size(player.get_sword_size())
	player.apply_knockback(player.aim_direction, 75)
	EventBus.sword_slash_sound.emit()
	player.can_swing += 1
	player.sword_swung.emit()

func Exit() -> void:
	player.body.slash_hurt_box.clear_effects()
	player.body.sword.end_attack()
	player.body.slash_vfx.visible = false
	last_attack_end_msec = Time.get_ticks_msec()
	player.show_hands(true)
	player.enable_jump()
	player.swing_cooldown.wait_time = player.get_sword_cd()
	player.swing_cooldown.start()

func Process(_delta: float) -> State:
	if finished:
		return idle
	var deceleration: float = player.get_move_deceleration()
	player.velocity.x = move_toward(player.velocity.x, 0, deceleration * _delta)
	return null

func Physics(_delta: float) -> State:
	return null

func HandleInput(_event: InputEvent) -> State:
	return null

func is_attack_animation(anim_name: StringName) -> bool:
	return anim_name in attack_animations

func _on_body_animation_finished(anim_name: StringName) -> void:
	if anim_name == current_animation:
		finished = true

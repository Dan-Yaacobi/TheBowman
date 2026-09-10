class_name SwingMainHandState extends MainHandState

@onready var idle: IdleMainHandState = $"../Idle"
@onready var swing_cooldown: Timer = $SwingCooldown
@onready var slash_hurt_box: HurtBox = $Sword/SlashHurtBox
@onready var slash_animation_player: AnimationPlayer = $"../../SlashEffect/SlashAnimationPlayer"
@onready var sword: Sword = $Sword

var finished: bool = false
var base_sword_scale: Vector2

func init() -> void:
	entity.animation_player.animation_finished.connect(swing_done)
	slash_hurt_box.monitoring = false
	base_sword_scale = sword.scale

func Enter() -> void:
	for ability in PlayerManager.player.get_sword_abilities():
		ability.activate_ability()
	EventBus.apply_player_knockback.emit(entity.hand_direction,75)
	EventBus.sword_slash_sound.emit()
	set_sword_size()
	swing_cooldown.wait_time = PlayerManager.player.get_sword_cd()
	entity.can_swing = false
	finished = false
	slash_hurt_box.base_damage = floor(PlayerManager.player.stats.sword_damage.value())
	slash_animation_player.play("SlashEffect")
	set_direction()
	if PlayerManager.player.direction_side:
		entity.animation_player.play("SwingLeft")
	else:
		entity.animation_player.play("Swing")
	slash_hurt_box.monitoring = true

func Exit() -> void:
	slash_hurt_box.monitoring = false
	swing_cooldown.start()
	reset_sword_size()
	
func Process(_delta: float) -> MainHandState:
	if finished:
		return idle
	set_direction()
	return null

func Physics(_delta: float) -> MainHandState:
	return null

func HandleInput(_event: InputEvent) -> MainHandState:
	return null


func swing_done(_anim) -> void:
	finished = true

func slash_hit_direction() -> void:
	if PlayerManager.player.direction_side:
		if slash_hurt_box.position.x > 0:
			slash_hurt_box.position.x *= -1
	else:
		if slash_hurt_box.position.x < 0:
			slash_hurt_box.position.x *= -1

func set_direction() -> void:
	slash_hit_direction()
	entity.set_swing_direction(PlayerManager.player.direction_side)

func set_sword_size() -> void:
	sword.scale *= PlayerManager.player.get_sword_size()

func reset_sword_size() -> void:
	sword.scale = base_sword_scale

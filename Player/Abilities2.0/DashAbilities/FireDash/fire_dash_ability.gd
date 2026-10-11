class_name FireDashAbility extends PlayerAbility

@export var aura_shader: Shader
# Size of the fireball. Raise until it wraps the player.
@export var aura_scale: float = 3.5
# Where the fireball sits relative to the player's origin (e.g. body center).
@export var aura_offset: Vector2 = Vector2(0, 4)

var aura: FireAura
var id: int
var cd_id: int
const FIRE_AURA = preload("uid://b0dj5ub6j4qqg")

func on_equipped() -> void:
	aura = FIRE_AURA.instantiate()
	aura.setup(aura_shader, aura_scale, aura_offset)
	PlayerManager.player.add_child(aura)
	EventBus.dash_ended.connect(_on_dash_ended)
	id = CustomVariables.get_buff_id()
	cd_id = CustomVariables.get_buff_id()
	PlayerManager.player.stats.dash_power.add_buff(id,1,Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.dash_cooldown.add_buff(cd_id,1,Stat.buff_type.MULTIPLICATIVE)
	
func on_unequipped() -> void:
	PlayerManager.player.stats.dash_power.remove_buff_completly(id,Stat.buff_type.MULTIPLICATIVE)
	PlayerManager.player.stats.dash_cooldown.remove_buff_completly(cd_id,Stat.buff_type.MULTIPLICATIVE)
	EventBus.dash_ended.disconnect(_on_dash_ended)
	if is_instance_valid(aura):
		aura.queue_free()
	aura = null

func get_tooltip() -> String:
	return "Turns into a fireball when dashing"

func get_tooltip_color() -> Color:
	return Color.ORANGE_RED
	
func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if is_instance_valid(aura):
		aura.ignite()
		PlayerManager.player.start_invincibilty()

func _on_dash_ended() -> void:
	if is_instance_valid(aura):
		aura.extinguish()

class_name FireDashAbility extends PlayerAbility

@export var aura_shader: Shader
# Size of the fireball. Raise until it wraps the player.
@export var aura_scale: float = 3.5
# Where the fireball sits relative to the player's origin (e.g. body center).
@export var aura_offset: Vector2 = Vector2(0, 4)

var aura: FireAura
const FIRE_AURA = preload("uid://b0dj5ub6j4qqg")

func on_equipped() -> void:
	aura = FIRE_AURA.instantiate()
	aura.ability = self
	aura.setup(aura_shader, aura_scale, aura_offset)
	PlayerManager.player.add_child(aura)
	EventBus.dash_ended.connect(_on_dash_ended)

func on_unequipped() -> void:
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
		
func _on_dash_ended() -> void:
	if is_instance_valid(aura):
		aura.extinguish()

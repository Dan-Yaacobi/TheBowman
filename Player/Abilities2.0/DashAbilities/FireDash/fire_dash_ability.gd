class_name FireDashAbility extends PlayerAbility

# Set the trigger type to DASH in the inspector, like your other dash abilities.

@export var aura_shader: Shader
# Size of the fireball. Raise until it wraps the player.
@export var aura_scale: float = 2.0
# Where the fireball sits relative to the player's origin (e.g. body center).
@export var aura_offset: Vector2 = Vector2(0, -8)

var aura: FireAura
const FIRE_AURA = preload("uid://b0dj5ub6j4qqg")

func on_equipped() -> void:
	aura = FIRE_AURA.instantiate()
	aura.setup(aura_shader, aura_scale, aura_offset)
	PlayerManager.player.add_child(aura)
	EventBus.dash_ended.connect(_on_dash_ended)

func on_unequipped() -> void:
	EventBus.dash_ended.disconnect(_on_dash_ended)
	if is_instance_valid(aura):
		aura.queue_free()
	aura = null

func activate_ability(_target: Node2D = null , _activator: Node2D = null, _result: DamageResult = null) -> void:
	if is_instance_valid(aura):
		aura.ignite()
	# Turn on invulnerability here, using whatever your hit-invulnerability uses.

func _on_dash_ended() -> void:
	if is_instance_valid(aura):
		aura.extinguish()
	# Turn invulnerability off here.

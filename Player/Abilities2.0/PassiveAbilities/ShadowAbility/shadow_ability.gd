class_name ShadowAbility extends PlayerPassiveAbility
## Keeps the shadow look. Each hit you take has a chance to pass through you harmlessly;
## on a dodge you briefly flicker into shadow.

const SHADOW_EFFECT = preload("uid://bsx66xsp8vyxd")
const FLICKER_COLOR: Color = Color(0.35, 0.05, 0.5, 0.25)

## Dodge chance (0-1) before the color level. Capped at max_dodge_chance.
@export var dodge_chance: float = 0.15
@export var max_dodge_chance: float = 0.5

var new_effect: CPUParticles2D
var arrow_effect: ShadowArrow

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	arrow_effect = ShadowArrow.new()
	player.modulate = "ed4fffc6"
	new_effect = SHADOW_EFFECT.instantiate()
	player.add_child(new_effect)
	player.stats.arrow_visual_effects.append(arrow_effect)
	player.dodge_chance = _chance()
	if not player.dodged.is_connected(_on_dodged):
		player.dodged.connect(_on_dodged)

func refresh_power() -> void:
	PlayerManager.player.dodge_chance = _chance()

func on_unequipped() -> void:
	var player: Player = PlayerManager.player
	player.modulate = Color.WHITE
	player.stats.arrow_visual_effects.erase(arrow_effect)
	player.dodge_chance = 0.0
	if player.dodged.is_connected(_on_dodged):
		player.dodged.disconnect(_on_dodged)
	if is_instance_valid(new_effect):
		new_effect.queue_free()
		new_effect = null

func _chance() -> float:
	return minf(dodge_chance * power(), max_dodge_chance)

func _on_dodged() -> void:
	var player: Player = PlayerManager.player
	var tween: Tween = player.create_tween()
	tween.tween_property(player.body, "modulate", FLICKER_COLOR, 0.05)
	tween.tween_property(player.body, "modulate", Color.WHITE, 0.25)
	var puff: CPUParticles2D = CPUParticles2D.new()
	puff.one_shot = true
	puff.explosiveness = 0.85
	puff.amount = 14
	puff.lifetime = 0.45
	puff.local_coords = false
	puff.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	puff.emission_sphere_radius = 8.0
	puff.spread = 180.0
	puff.gravity = Vector2(0, -30)
	puff.initial_velocity_min = 10.0
	puff.initial_velocity_max = 30.0
	puff.scale_amount_min = 2.0
	puff.scale_amount_max = 3.5
	puff.color = Color(0.3, 0.05, 0.45, 0.8)
	puff.finished.connect(puff.queue_free)
	player.add_child(puff)
	puff.emitting = true

func get_tooltip() -> String:
	return "Hits have a %d%% chance to pass through your shadow" % roundi(_chance() * 100.0)

func get_tooltip_color() -> Color:
	return Color.MEDIUM_SLATE_BLUE

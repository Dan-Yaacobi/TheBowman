class_name ThornRingAbility extends PlayerPassiveAbility
## Taking damage fires a ring of arrows around you. They carry your quiver's on-hit effects (its debuff).

@export var arrow_count: int = 8
## Draw strength of the thorn arrows (sets their speed and base damage).
@export var shot_power: float = 0.6

const THORN_TINT: Color = Color(0.75, 1.0, 0.6)

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if not player.took_hit.is_connected(_on_took_hit):
		player.took_hit.connect(_on_took_hit)

func on_unequipped() -> void:
	var player: Player = PlayerManager.player
	if player.took_hit.is_connected(_on_took_hit):
		player.took_hit.disconnect(_on_took_hit)

func _on_took_hit() -> void:
	# Deferred: hits land inside physics callbacks, where new arrows (areas) can't be added.
	_fire_ring.call_deferred()

func _fire_ring() -> void:
	var player: Player = PlayerManager.player
	if player == null or not player.is_inside_tree() or player.is_dead():
		return
	var main_hand: PlayerMainHand = player.main_hand
	var quiver_abilities: Array[PlayerAbility] = _quiver_abilities(player)
	var origin: Vector2 = player.global_position + Vector2(0, -6)
	var start: float = randf() * TAU
	for i in arrow_count:
		var direction: Vector2 = Vector2.from_angle(start + TAU * i / float(maxi(arrow_count, 1)))
		var thorn: Arrow = main_hand.fire_at(direction, shot_power, origin, quiver_abilities, false)
		thorn.regular_shot = false
		thorn.damage = maxi(1, roundi(thorn.damage * power()))
		thorn.modulate = THORN_TINT

## The equipped quiver's main ability and rolled minors (only hit effects get attached).
func _quiver_abilities(player: Player) -> Array[PlayerAbility]:
	var result: Array[PlayerAbility] = []
	var quiver: EquipmentData = player.stats.arrow
	if quiver == null:
		return result
	if quiver.ability:
		result.append(quiver.ability)
	for bonus in quiver.bonus_abilities:
		if bonus:
			result.append(bonus)
	return result

func get_tooltip() -> String:
	return "Taking damage fires a ring of %d arrows that carry your quiver's effect" % arrow_count

func get_tooltip_color() -> Color:
	return THORN_TINT

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

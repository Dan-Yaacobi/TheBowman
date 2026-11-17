class_name ObsidianSpire extends RootedEnemy
## A jagged black crystal rooted on an island, lava in its cracks. Glows brighter as it charges,
## then bursts a ring of shards in every direction.

@onready var burst_point: Marker2D = $BurstPoint

var spire_data: ObsidianSpireData
var _turned: bool = false


func setup_rooted() -> void:
	spire_data = stats as ObsidianSpireData


## 0 = normal, 1 = full charge glow.
func set_glow(amount: float) -> void:
	sprite.self_modulate = Color.WHITE.lerp(spire_data.glow_color, clampf(amount, 0.0, 1.0))


func on_dormant_changed(_dormant: bool) -> void:
	set_glow(0.0)


## Fires shard_count shards evenly around the spire.
func burst() -> void:
	if spire_data.shard_scene == null:
		return
	var count: int = spire_data.shard_count
	var step: float = TAU / count
	var offset: float = step * 0.5 if _turned else 0.0
	if spire_data.alternate_gaps:
		_turned = not _turned
	for i: int in count:
		var shard: ObsidianShard = spire_data.shard_scene.instantiate()
		tag_attack(shard)
		shard.data = shard.data.duplicate()
		shard.data.damage = roundi(spire_data.shard_damage * stats.damage_dealt_multiplier.value())
		shard.data.knockback = spire_data.shard_knockback
		shard.data.move_speed = roundi(spire_data.shard_speed)
		shard.lifetime = spire_data.shard_lifetime
		shard.direction = Vector2.RIGHT.rotated(offset + step * i)
		shard.global_position = burst_point.global_position
		shard.was_fired = true
		_wire_hit_effects(shard.hurt_box, true)
		get_parent().add_child(shard)

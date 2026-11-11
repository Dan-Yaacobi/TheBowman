class_name ShatterMinor extends MinorAbility
## Frozen enemies shatter into value ice shards when they die. Shards reuse the Riftbow punch projectile
## with the Ice Shards arrow sprite.

const SHARD_TEXTURE_PATH: String = "res://Items/Equipments/Quivers/Sprites/Arrows/IceShrapnel.png"

@export var shard_range: float = 70.0
## Shard damage as a multiplier of your base arrow hit.
@export var shard_damage_mult: float = 0.5

func on_equipped() -> void:
	if not EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.connect(_on_enemy_died)

func on_unequipped() -> void:
	if EventBus.enemy_died.is_connected(_on_enemy_died):
		EventBus.enemy_died.disconnect(_on_enemy_died)

func _on_enemy_died(enemy: Enemy) -> void:
	if not is_instance_valid(enemy) or not enemy.has_debuff(CustomVariables.FREEZE_DEBUFF_ID):
		return
	var damage: int = maxi(1, roundi(PlayerManager.player.main_hand.get_base_hit_damage() * shard_damage_mult * power()))
	var count: int = maxi(value, 1)
	var start_angle: float = randf() * TAU
	for i in count:
		var shard: RiftFist = RiftFist.new()
		shard.texture_path = SHARD_TEXTURE_PATH
		shard.sprite_scale = 0.5
		shard.speed = 240.0
		shard.max_distance = shard_range
		shard.hit_radius = 5.0
		shard.damage = damage
		shard.knockback = 60.0
		shard.ignore = enemy
		shard.direction = Vector2.from_angle(start_angle + TAU * i / count)
		shard.global_position = enemy.global_position
		EventBus.summon_effect.emit(shard)

func get_tooltip() -> String:
	return "Frozen enemies shatter into %d shards when killed" % value

func get_type() -> TriggerType:
	return TriggerType.PASSIVE

func get_tooltip_color() -> Color:
	return Color.LIGHT_BLUE

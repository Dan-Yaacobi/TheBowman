class_name VenomBloom extends RootedEnemy
## A carnivorous plant rooted on an island. Spits a fan of poison stings at the player and bites
## anyone who comes right up to it.

@onready var bite_hurt_box: HurtBox = $BiteHurtBox
@onready var _bite_shape: CollisionShape2D = $BiteHurtBox/CollisionShape2D
@onready var sting_point: Marker2D = $StingPoint

var bloom_data: VenomBloomData
## Seconds left before another bite can start
var bite_cooldown_left: float = 0.0


func setup_rooted() -> void:
	bloom_data = stats as VenomBloomData
	bite_hurt_box.base_damage = bloom_data.bite_damage
	bite_hurt_box.knockback_power = bloom_data.bite_knockback
	bite_hurt_box.damage_multiplier = hurt_box.damage_multiplier
	bite_hurt_box.add_before_effect(_aim_bite_knockback)
	set_bite_active(false)


func _physics_process(delta: float) -> void:
	super(delta)
	if bite_cooldown_left > 0.0:
		bite_cooldown_left -= delta


func on_dormant_changed(dormant: bool) -> void:
	if dormant:
		set_bite_active(false)


## The art faces right.
func face_the_player() -> void:
	if PlayerManager.player:
		var left: bool = PlayerManager.player.global_position.x < global_position.x
		sprite.flip_h = left
		_bite_shape.position.x = absf(_bite_shape.position.x) * (-1.0 if left else 1.0)
		sting_point.position.x = absf(sting_point.position.x) * (-1.0 if left else 1.0)


func is_player_in_bite_range() -> bool:
	var player: Node2D = PlayerManager.player
	if player == null:
		return false
	var offset: Vector2 = player.global_position - global_position
	return absf(offset.x) <= bloom_data.bite_range and absf(offset.y) <= bloom_data.bite_height


func set_bite_active(active: bool) -> void:
	bite_hurt_box.set_deferred("monitoring", active)


## Spits sting_count stings in a fan centred on the player.
func spit() -> void:
	var player: Node2D = PlayerManager.player
	if bloom_data.sting_scene == null or player == null:
		return
	var aim: float = (player.global_position - sting_point.global_position).angle()
	var spread: float = deg_to_rad(bloom_data.sting_spread)
	var first: float = aim - spread * (bloom_data.sting_count - 1) * 0.5
	for i: int in bloom_data.sting_count:
		var sting: ObsidianShard = bloom_data.sting_scene.instantiate()
		tag_attack(sting)
		sting.data = sting.data.duplicate()
		sting.data.damage = roundi(bloom_data.sting_damage * stats.damage_dealt_multiplier.value())
		sting.data.knockback = bloom_data.sting_knockback
		sting.data.move_speed = roundi(bloom_data.sting_speed)
		sting.lifetime = bloom_data.sting_lifetime
		sting.direction = Vector2.RIGHT.rotated(first + spread * i)
		sting.global_position = sting_point.global_position
		sting.was_fired = true
		get_parent().add_child(sting)
		# After add_child: the sting's hurt_box is an @onready var
		_wire_hit_effects(sting.hurt_box, true)


func _aim_bite_knockback(_entity: GameEntity, _hurt_box: HurtBox) -> void:
	var dir: Vector2 = bloom_data.bite_launch_direction
	var side: float = signf(PlayerManager.player.global_position.x - global_position.x)
	if side == 0.0:
		side = 1.0
	bite_hurt_box.knockback_dir = Vector2(absf(dir.x) * side, dir.y).normalized()

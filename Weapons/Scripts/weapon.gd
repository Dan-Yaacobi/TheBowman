class_name Weapon extends Node2D

signal combo_loss
signal combo_gained
signal arrow_hit_sound
signal critical_hit
signal leeched(amount: int,enemy_position: Vector2)
static var player: Player

@export var weapon_data: WeaponData
const COMBO_ARROW_EFFECT = preload("res://Weapons/Effects/ComboArrowEffect/ComboArrowEffect.tscn")
var regular_attack: bool = true

func shoot(_offset: bool) -> void:
	var offset: Vector2 = Vector2.ZERO
	if _offset:
		offset = Vector2(randf_range(-0.2,0.2),randf_range(-0.2,0.2))
		
	var arrow = PlayerManager.player.current_arrow
	arrow.global_position += offset
	if weapon_data.can_pierce:
		arrow.can_pierce = true
		
	if weapon_data.arrows_explode:
		arrow.can_explode = true
		
	if weapon_data.crit_arrows:
		arrow.can_crit = true
		arrow.crit_chance = player.stats.crit_chance
		arrow.crit_hit.connect(crit)
		
	if weapon_data.can_stun:
		arrow.can_stun = true
		arrow.stun_chance = player.stats.stun_chance
		
	if weapon_data.can_leech:
		arrow.can_leechlife = true
		arrow.leech_chance = player.stats.leech_chance
		arrow.leeched.connect(leech)
	
		#arrow.rotate(set_arrow_rotation())
	arrow.regular_shot = regular_attack
		#player.get_parent().call_deferred("add_child",arrow)

#func set_arrow_rotation() -> float:
	#var player_pos = player.global_position
	#var mouse_pos = player.get_global_mouse_position()
	#var angle_rotation: float = (player_pos - mouse_pos).angle()
	#return angle_rotation
	
func init_weapon(_player: Player, _weapon: Weapon) -> void:
	player = _player
	player.add_child(_weapon)
	
	pass
#
#func instance_arrow(ARROW: PackedScene, the_position, _offset) -> Arrow:
	#if ARROW != null:
		#var arrow: Arrow = ARROW.instantiate()
		#arrow.arrow_hit_sound.connect(emit_hit_sound)
		#arrow.data.damage = weapon_data.damage
		#arrow.direction = player.get_shoot_direction() + _offset
		#
		#if weapon_data.combo_buff_activated:
			#var combo_effect: CPUParticles2D = COMBO_ARROW_EFFECT.instantiate()
			#combo_effect.gravity = -arrow.direction
			#arrow.add_child(combo_effect)
			#arrow.data.damage = weapon_data.damage * 2
		#else:
			#arrow.data.damage = weapon_data.damage
		#arrow.arrow_missed.connect(missed)
		#arrow.arrow_hit.connect(hit)
		#arrow.global_position = the_position
		#arrow.z_index = -1
		#return arrow
	#return null

func leech(amount: int,enemy_position: Vector2) -> void:
	leeched.emit(amount,enemy_position)
	
func crit() -> void:
	critical_hit.emit()
	
func emit_hit_sound() -> void:
	arrow_hit_sound.emit()

func missed() -> void:
	combo_loss.emit()
	pass

func hit() -> void:
	combo_gained.emit()
	pass

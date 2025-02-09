class_name Companion extends CharacterBody2D

@onready var attack_area: Area2D = $AttackArea
@export var data: CompanionData
var enemies_in_range: Array[Enemy]
var curr_enemy_att: Enemy
var area: Area2D

var animation_player: AnimationPlayer

func _ready() -> void:
	ready_methods()

func find_nearest_enemy() -> Enemy:
	
	return null

func focus_enemy(b) -> void:
	if b is Enemy:
		if curr_enemy_att == null:
			curr_enemy_att = b
		if not b.died.is_connected(remove_enemy):
			b.died.connect(remove_enemy)
		enemies_in_range.append(b)

func remove_enemy(b) -> void:
	enemies_in_range.erase(b)
	if not b.died.is_connected(remove_enemy):
		b.died.disconnect(remove_enemy)
	pass
	
func unfocus_enemy(b) -> void:
	remove_enemy(b)
	if curr_enemy_att == b:
		curr_enemy_att = null
		if enemies_in_range.size() > 0:
			curr_enemy_att = enemies_in_range.pick_random()
	
		
func update_animation(anim: String) -> void:
	animation_player.play(anim)

func ready_methods() -> void:
	area = attack_area
	area.body_entered.connect(focus_enemy)
	area.body_exited.connect(unfocus_enemy)
	pass
	

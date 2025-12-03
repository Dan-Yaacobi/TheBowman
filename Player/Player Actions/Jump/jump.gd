class_name JumpAction extends Node2D

@onready var player: Player = $".."
@onready var jump_particles: CPUParticles2D = $JumpParticles

var jumps: int = 1
var jump_flip: bool = false
var jump_flip_chance: int = 2

func _ready() -> void:
	jumps = player.stats.max_jumps

func jump() -> void:
	if jumps > 0:
		#player.body.update_animation("Jump")
		player.velocity.y = 0
		player.velocity.y -= player.stats.jump_height + player.get_agility()
		jumps -= 1
		jump_particles.restart()
		return

		
func reset_jumps(_var1,_var2,_var3,_var4) -> void:
	if _var2 is TileMapLayer or _var2 is PhysicsBody2D:
		if player.stats.hp > 0:
			jump_flip = false
			#if jumps == 0:
			set_jumps()

func set_jumps() -> void:
	jumps = player.stats.max_jumps + int(player.get_agility() / 10)

class_name JumpAction extends Node2D

@onready var player: Player = $".."
@onready var jump_particles: CPUParticles2D = $JumpParticles

var jumps: int = 1
var jump_flip: bool = false
var jump_flip_chance: int = 2

func _ready() -> void:
	jumps = player.stats.max_jumps
	
func _physics_process(delta: float) -> void:
	jumping_flip()

func jump() -> void:
	if jumps > 0:
		player.update_animation("Jump")
		player.velocity.y = 0
		player.velocity.y -= player.stats.jump_height
		jumps -= 1
		jump_particles.restart()

		var flip_jump_random: int = randi_range(0,jump_flip_chance)
		if flip_jump_random == 0:
			jump_flip = true
		else:
			jump_flip = false
	pass

func jumping_flip() -> void:
	if jump_flip:
		player.body.rotation += 0.15
	else:
		player.body.rotation = 0
		
func reset_jumps(_var1,_var2,_var3,_var4) -> void:
	if _var2 is TileMapLayer:
		if player.stats.hp > 0:
			jump_flip = false
			#if jumps == 0:
			set_jumps()

func set_jumps() -> void:
	jumps = player.stats.max_jumps

class_name TreasureChest extends FallingObject

@onready var animation_player: AnimationPlayer = $Sprite2D/AnimationPlayer
@onready var area: Area2D = $Area2D
@onready var audio_stream_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var cpu_particles_2d: CPUParticles2D = $CPUParticles2D

var falling_state: bool = true

func _ready() -> void:
	area.area_entered.connect(take_hit)
	animation_player.play("Idle")
	mass = data.mass
	self.gravity_scale = 0.05
	
func _physics_process(delta: float) -> void:
	pass

func destroyed() -> void:
	
	cpu_particles_2d.emitting = false
	animation_player.play("Destroyed")
	audio_stream_player.play()
	drop_loot()
	await audio_stream_player.finished
	queue_free()

func drop_loot() -> void:
	for drop in data.drops:
		if drop.drop_chance():
			spawn_drop(drop)
		

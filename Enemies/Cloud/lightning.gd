class_name Lightning extends Line2D

signal finished

@export var segments: int = 10
@export var max_offset: float = 20.0
@export var flicker: bool = false
@onready var hurt_box: HurtBox = $"../HurtBox"
@onready var lightning_impact: CPUParticles2D = $"../HurtBox/LightningImpact"
@onready var audio_stream_player: AudioStreamPlayer2D = $"../AudioStreamPlayer2D"

var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	width = 4                       # make it visible
	default_color = Color.CYAN      # or whatever

func _process(_delta: float) -> void:
	if flicker and get_point_count() > 0:
		# If you want flicker you should call generate_lightning_global()
		# every frame from outside with updated positions.
		pass


func generate_lightning_global(start_global: Vector2, end_global: Vector2) -> void:
	# Put the Line2D's origin at the start of the bolt
	global_position = start_global

	# Convert the end point into this node's local space
	var local_start := Vector2.ZERO
	var local_end := to_local(end_global)

	_generate_lightning_local(local_start, local_end)


func _generate_lightning_local(a: Vector2, b: Vector2) -> void:
	clear_points()
	hurt_box.monitoring = true
	var direction := b - a
	var length := direction.length()
	if length == 0.0:
		add_point(a)
		return

	var normal := Vector2(-direction.y, direction.x).normalized()

	for i in range(segments + 1):
		var t := float(i) / float(segments)
		var base := a + direction * t

		var offset := 0.0
		if i != 0 and i != segments:
			offset = rng.randf_range(-max_offset, max_offset)

		var final_pos := base + normal * offset
		add_point(final_pos)
		hurt_box.position = final_pos
		await get_tree().create_timer(0.005).timeout
		if not is_inside_tree():  # node was freed mid-coroutine
			return

	lightning_impact.emitting = true
	hurt_box.monitoring = false
	audio_stream_player.pitch_scale = randf_range(0.8,1.2)
	audio_stream_player.play()
	await get_tree().create_timer(1.0).timeout
	if not is_inside_tree():  # node was freed mid-coroutine
		return
	finished.emit()

func done() -> void:
	
	clear_points()
	
func _exit_tree() -> void:
	# Safety net: if we're torn down mid-coroutine, disarm the hurtbox
	if is_instance_valid(hurt_box):
		hurt_box.monitoring = false

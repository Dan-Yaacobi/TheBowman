class_name SecondSkinAbility extends PlayerPassiveAbility
## Health milestone. A glowing outline around the archer blocks one hit, then comes back after a while without taking damage.

## Seconds without taking damage before the shield returns.
@export var recharge_time: float = 30.0
## Colour of the outline and of the shards when it breaks.
@export var outline_color: Color = Color(1.0, 0.86, 0.45, 1.0)
## Seconds between glints sweeping across the outline.
@export var glint_interval: float = 2.5
## Pixel shards thrown out when the shield blocks a hit.
@export var shard_count: int = 16

var _bubble: ShieldBubble

func on_equipped() -> void:
	var player: Player = PlayerManager.player
	if is_instance_valid(_bubble):
		return
	_bubble = ShieldBubble.new()
	_bubble.name = "SecondSkin"
	_bubble.player = player
	_bubble.recharge_time = recharge_time
	_bubble.outline_color = outline_color
	_bubble.glint_interval = glint_interval
	_bubble.shard_count = shard_count
	player.add_child(_bubble)

func on_unequipped() -> void:
	if is_instance_valid(_bubble):
		_bubble.remove()
	_bubble = null

func get_tooltip() -> String:
	return "A shield blocks one hit, and returns after %ds without taking damage" % roundi(recharge_time)

## Owns the shield's state: gives the player a hit shield while up, draws the outline,
## and restarts the recharge whenever the player takes damage.
## The outline is made of flat-coloured copies of the player's sprites, shifted 1px
## in each direction and drawn behind them, so only a 1px rim shows.
class ShieldBubble extends Node2D:
	const SOURCE_SPRITES: Array[String] = [
		"PlayerBody/Sprite2D",
		"PlayerBody/Quiver",
		"PlayerBody/Sword/SwordSocket/Blade",
		"PlayerMainHand/Sprite2D",
		"PlayerOffHand/Sprite2D",
		"PlayerOffHand/Bow/Sprite2D",
	]
	const OFFSETS: Array[Vector2] = [Vector2.LEFT, Vector2.RIGHT, Vector2.UP, Vector2.DOWN]
	## Diagonal (x - y) range the glint sweeps across, in pixels relative to the player.
	const GLINT_START: float = -60.0
	const GLINT_END: float = 75.0
	const GLINT_DURATION: float = 0.45
	## Rows the fill-in sweeps from (feet) to (head), relative to the player.
	const REVEAL_FROM: float = 30.0
	const REVEAL_TO: float = -55.0
	const REVEAL_DURATION: float = 0.4
	const HIDDEN_REVEAL: float = 1000.0

	var player: Player
	var recharge_time: float = 30.0
	var outline_color: Color = Color(1.0, 0.86, 0.45, 1.0)
	var glint_interval: float = 2.5
	var shard_count: int = 16

	var _up: bool = false
	var _recharge: Timer
	var _glint_timer: Timer
	var _material: ShaderMaterial
	var _outline: Node2D
	var _sources: Array[Sprite2D] = []
	var _copies: Array[Sprite2D] = []
	var _shards: CPUParticles2D
	var _reveal_tween: Tween
	var _glint_tween: Tween

	func _ready() -> void:
		# Run after the player's AnimationPlayers so copies match this frame's pose.
		process_priority = 1000
		_material = ShaderMaterial.new()
		_material.shader = load("res://Player/Abilities2.0/MilestoneAbilities/Health/second_skin_outline.gdshader")
		_material.set_shader_parameter("tint", outline_color)
		_material.set_shader_parameter("reveal_y", HIDDEN_REVEAL)
		_build_outline()
		_build_shards()

		_recharge = Timer.new()
		_recharge.one_shot = true
		_recharge.process_callback = Timer.TIMER_PROCESS_PHYSICS
		_recharge.timeout.connect(_raise)
		add_child(_recharge)

		_glint_timer = Timer.new()
		_glint_timer.wait_time = glint_interval
		_glint_timer.timeout.connect(_play_glint)
		add_child(_glint_timer)

		player.shield_blocked.connect(_on_player_shield_blocked)
		player.took_hit.connect(_on_player_took_hit)
		_raise()

	## Takes the shield away cleanly before freeing.
	func remove() -> void:
		if _up:
			player.hit_shields = maxi(0, player.hit_shields - 1)
		_up = false
		queue_free()

	func _build_outline() -> void:
		_outline = Node2D.new()
		_outline.name = "Outline"
		# Below every player sprite (lowest one sits at absolute z 0).
		_outline.z_index = -1
		add_child(_outline)
		for path: String in SOURCE_SPRITES:
			var source: Sprite2D = player.get_node_or_null(path) as Sprite2D
			if source == null:
				continue
			for i: int in OFFSETS.size():
				var copy: Sprite2D = Sprite2D.new()
				copy.material = _material
				_outline.add_child(copy)
				_sources.append(source)
				_copies.append(copy)

	func _build_shards() -> void:
		_shards = CPUParticles2D.new()
		_shards.name = "Shards"
		_shards.emitting = false
		_shards.one_shot = true
		_shards.explosiveness = 1.0
		_shards.amount = maxi(1, shard_count)
		_shards.lifetime = 0.6
		_shards.local_coords = false
		_shards.position = Vector2(0, -10)
		_shards.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		_shards.emission_sphere_radius = 10.0
		_shards.direction = Vector2.UP
		_shards.spread = 180.0
		_shards.initial_velocity_min = 70.0
		_shards.initial_velocity_max = 140.0
		_shards.gravity = Vector2(0, 350)
		_shards.damping_min = 40.0
		_shards.damping_max = 80.0
		_shards.scale_amount_min = 1.0
		_shards.scale_amount_max = 2.0
		_shards.color = outline_color
		var fade: Gradient = Gradient.new()
		fade.set_color(0, Color.WHITE)
		fade.set_color(1, Color(1, 1, 1, 0))
		_shards.color_ramp = fade
		_shards.z_index = 3
		add_child(_shards)

	func _raise() -> void:
		if _up:
			return
		_up = true
		player.hit_shields += 1
		_outline.visible = true
		_material.set_shader_parameter("reveal_y", REVEAL_FROM)
		if _reveal_tween:
			_reveal_tween.kill()
		_reveal_tween = create_tween()
		_reveal_tween.tween_property(_material, "shader_parameter/reveal_y", REVEAL_TO, REVEAL_DURATION)
		_reveal_tween.tween_callback(_play_glint)
		_glint_timer.start()

	func _play_glint() -> void:
		if _glint_tween:
			_glint_tween.kill()
		_material.set_shader_parameter("glint_pos", GLINT_START)
		_glint_tween = create_tween()
		_glint_tween.tween_property(_material, "shader_parameter/glint_pos", GLINT_END, GLINT_DURATION)

	func _on_player_shield_blocked() -> void:
		if not _up:
			return
		_up = false
		_recharge.start(recharge_time)
		_glint_timer.stop()
		if _reveal_tween:
			_reveal_tween.kill()
		_outline.visible = false
		_material.set_shader_parameter("reveal_y", HIDDEN_REVEAL)
		_shards.restart()
		CombatTextSpawner.spawn(player.global_position, "Blocked", outline_color)
		GeneralFunctions.hit_freeze(0.06)

	## Real damage while the shield is down pushes the recharge back.
	func _on_player_took_hit() -> void:
		if not _up:
			_recharge.start(recharge_time)

	func _process(_delta: float) -> void:
		if not _outline.visible:
			return
		_material.set_shader_parameter("origin", player.global_position)
		for i: int in _copies.size():
			_sync_copy(_copies[i], _sources[i], OFFSETS[i % OFFSETS.size()])

	## Mirrors a source sprite's look and pose, shifted by one pixel.
	func _sync_copy(copy: Sprite2D, source: Sprite2D, shift: Vector2) -> void:
		if not is_instance_valid(source) or not source.is_visible_in_tree():
			copy.visible = false
			return
		copy.visible = true
		copy.texture = source.texture
		copy.hframes = source.hframes
		copy.vframes = source.vframes
		copy.frame = source.frame
		copy.flip_h = source.flip_h
		copy.flip_v = source.flip_v
		copy.centered = source.centered
		copy.offset = source.offset
		copy.region_enabled = source.region_enabled
		copy.region_rect = source.region_rect
		var xform: Transform2D = source.global_transform
		xform.origin += shift
		copy.global_transform = xform

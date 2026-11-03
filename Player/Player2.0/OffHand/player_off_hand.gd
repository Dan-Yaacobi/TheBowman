class_name PlayerOffHand extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bow_sprite: Sprite2D = $Bow/Sprite2D
@onready var string: Line2D = $String

@onready var bow_top: Node2D = $Bow/BowTop
@onready var bow_bottom: Node2D = $Bow/BowBottom

var string_pull_target: Node2D = null
@export var hold_rotation_offset_degrees: float = 0.0
## In-hand size for bows with fit data. Each bow is scaled so its visible art (mostly width, some height) matches this.
@export var bow_size: float = 31.0

const BOW_WIDTH_WEIGHT: float = 0.65

var default_bow_top: Vector2
var default_bow_bottom: Vector2
var default_bow_offset: Vector2

const CRACKLE_SEGMENTS: int = 6
const CRACKLE_JITTER: float = 1.2
const CRACKLE_REFRESH: float = 0.05
const PULSE_SPEED: float = 4.0

## Current bow's string look (EquipmentData "Bow fit" group).
var string_style: EquipmentData.StringStyle = EquipmentData.StringStyle.PLAIN
var string_glow_color: Color = Color(1, 1, 1, 0)
var string_glow: Line2D
var _crackle_timer: float = 0.0
var _crackle_offsets: PackedFloat32Array = PackedFloat32Array()
var _time: float = 0.0
## Gold glow and sparks on the bow while the next shot is guaranteed perfect.
const CHARGED_GLOW: Color = Color(1.6, 1.35, 0.6)
var _charged_sparks: CPUParticles2D

var position_target: Node2D = null
var rotation_target: Node2D = null
var facing_left: bool = false
func _ready() -> void:
	default_bow_top = bow_top.position
	default_bow_bottom = bow_bottom.position
	default_bow_offset = bow_sprite.offset
	string_glow = Line2D.new()
	string_glow.show_behind_parent = true
	string_glow.begin_cap_mode = Line2D.LINE_CAP_ROUND
	string_glow.end_cap_mode = Line2D.LINE_CAP_ROUND
	string_glow.visible = false
	string.add_child(string_glow)
	_charged_sparks = _make_charged_sparks()
	bow_sprite.add_child(_charged_sparks)
	hide_bow()

func _process(_delta: float) -> void:
	process_priority = 1
	if position_target:
		global_position = position_target.global_position
	if rotation_target:
		var offset: float = deg_to_rad(hold_rotation_offset_degrees)
		rotation = rotation_target.rotation + (-offset if facing_left else offset)
	else:
		rotation = PI if facing_left else 0.0
	_update_string(_delta)
	_update_charged_glow()
	
func set_facing(_facing_left: bool) -> void:
	facing_left = _facing_left
	scale.x = absf(scale.x)
	scale.y = -absf(scale.y) if facing_left else absf(scale.y)
	
func rest(shoulder: Node2D) -> void:
	position_target = shoulder
	rotation_target = null
	string_pull_target = null
	z_index = -2

func hold(hand: Node2D, string_point: Node2D, grip: Node2D) -> void:
	position_target = grip
	rotation_target = hand
	string_pull_target = string_point
	z_index = 0

func _update_string(delta: float = 0.0) -> void:
	var top: Vector2 = string.to_local(bow_top.global_position)
	var bottom: Vector2 = string.to_local(bow_bottom.global_position)
	var middle: Vector2 = (top + bottom) / 2.0
	if string_pull_target:
		middle = string.to_local(string_pull_target.global_position)
	var points: PackedVector2Array = PackedVector2Array([top, middle, bottom])
	if string_style == EquipmentData.StringStyle.CRACKLE:
		points = _crackle(points, delta)
	string.points = points
	string_glow.points = points
	_time += delta
	if string_style == EquipmentData.StringStyle.PULSE:
		var pulse: float = 0.55 + 0.45 * sin(_time * PULSE_SPEED)
		string_glow.default_color = Color(string_glow_color, string_glow_color.a * pulse)

## Splits each half of the string into jittering segments, re-rolled a few times a second.
func _crackle(points: PackedVector2Array, delta: float) -> PackedVector2Array:
	_crackle_timer -= delta
	if _crackle_timer <= 0.0 or _crackle_offsets.size() != CRACKLE_SEGMENTS * 2:
		_crackle_timer = CRACKLE_REFRESH
		_crackle_offsets.resize(CRACKLE_SEGMENTS * 2)
		for i in _crackle_offsets.size():
			_crackle_offsets[i] = randf_range(-CRACKLE_JITTER, CRACKLE_JITTER)
	var out: PackedVector2Array = PackedVector2Array([points[0]])
	for half in 2:
		var from: Vector2 = points[half]
		var to: Vector2 = points[half + 1]
		var normal: Vector2 = (to - from).orthogonal().normalized()
		for i in range(1, CRACKLE_SEGMENTS):
			out.append(from.lerp(to, i / float(CRACKLE_SEGMENTS)) + normal * _crackle_offsets[half * CRACKLE_SEGMENTS + i])
		out.append(to)
	return out

func _update_charged_glow() -> void:
	var player: Player = PlayerManager.player
	var charged: bool = player != null and player.main_hand.next_shot_perfect and bow_sprite.visible
	_charged_sparks.emitting = charged
	if charged:
		bow_sprite.modulate = Color.WHITE.lerp(CHARGED_GLOW, 0.5 + 0.5 * sin(_time * 8.0))
	else:
		bow_sprite.modulate = Color.WHITE

func _make_charged_sparks() -> CPUParticles2D:
	var sparks: CPUParticles2D = CPUParticles2D.new()
	sparks.emitting = false
	sparks.amount = 10
	sparks.lifetime = 0.5
	sparks.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparks.emission_rect_extents = Vector2(24, 8)
	sparks.direction = Vector2(0, -1)
	sparks.spread = 60.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = 15.0
	sparks.initial_velocity_max = 35.0
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.0
	sparks.color = Color(1.0, 0.85, 0.35)
	return sparks

func _apply_string_look(_data: EquipmentData) -> void:
	string.default_color = _data.string_color
	string.width = _data.string_width
	string_style = _data.string_style
	string_glow_color = _data.string_glow_color
	string_glow.default_color = _data.string_glow_color
	string_glow.width = _data.string_glow_width
	string_glow.visible = _data.string_style != EquipmentData.StringStyle.PLAIN and _data.string_glow_color.a > 0.0

func play_stage(stage: String, pull_speed: float) -> void:
	var anim: String = "Idle"
	if stage == "Pull":
		anim = "Pull"
	elif stage == "MaxPull":
		anim = "Max Pull" if animation_player.has_animation("Max Pull") else "Pull"
	if animation_player.assigned_animation == anim:
		return
	animation_player.speed_scale = pull_speed if anim == "Pull" else 1.0
	animation_player.play(anim)

func set_new_bow(_data: EquipmentData) -> void:
	if _data:
		bow_sprite.texture = _data.texture
		if _data.string_tip != Vector2.ZERO and _data.texture:
			_fit_bow(_data)
		else:
			bow_sprite.scale = _data.equipped_scale
			bow_sprite.offset = default_bow_offset
			bow_top.position = default_bow_top
			bow_bottom.position = default_bow_bottom
		_apply_string_look(_data)
		string.show()
		bow_sprite.show()

## Same size, grip on the hand, string on the tips - for any bow sprite with fit data.
func _fit_bow(_data: EquipmentData) -> void:
	var size: Vector2 = _data.texture.get_size()
	var right_tip: Vector2 = _data.string_tip
	var left_tip: Vector2 = Vector2(size.x - right_tip.x, right_tip.y)
	var bow_scale: float = bow_size / _bow_art_size(_data.texture)
	bow_sprite.scale = Vector2(bow_scale, bow_scale)
	bow_sprite.offset = size / 2.0 - _data.grip_point
	bow_top.position = bow_sprite.transform * (right_tip - _data.grip_point)
	bow_bottom.position = bow_sprite.transform * (left_tip - _data.grip_point)

## Visible art size in pixels: mostly width, some height, so wide and tall bows read about the same size.
func _bow_art_size(texture: Texture2D) -> float:
	var used: Rect2i = texture.get_image().get_used_rect()
	return maxf(pow(used.size.x, BOW_WIDTH_WEIGHT) * pow(used.size.y, 1.0 - BOW_WIDTH_WEIGHT), 1.0)

func hide_bow() -> void:
	string.hide()
	bow_sprite.hide()

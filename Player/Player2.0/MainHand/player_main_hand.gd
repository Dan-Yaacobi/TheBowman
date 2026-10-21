class_name PlayerMainHand extends Node2D

signal shot_power_amount(amount)
signal release
signal drawing_arrow

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hold_position: Node2D = $HoldPosition
@onready var main_hand_state_machine: MainHandStateMachine = $MainHandStateMachine
@onready var max_pull_state: MaxPullMainHandState = $MainHandStateMachine/MaxPull
@onready var arrow_position: Node2D = $ArrowPosition
@onready var sprite: Sprite2D = $Sprite2D
@onready var pulling: PullingMainHandState = $MainHandStateMachine/Pulling

@export var arrow: PackedScene
@export var arrow_texture: Texture
@export var min_shot_power: float = 0.1
@export var max_offset: float
@export var weak_shot_punish: float = 2.0
@onready var idle: IdleMainHandState = $MainHandStateMachine/Idle
@onready var perfect_release_particles: CPUParticles2D = $PerfectReleaseParticles

var current_arrow: Arrow = null
var hand_direction: Vector2
var shot_power: float
var off_hand: PlayerOffHand
var body: PlayerBody
var shot_offset: float = 0
var anchor: Node2D = null
var facing_left: bool = false

func _ready() -> void:
	main_hand_state_machine.Initialize(self)
	
func _process(_delta: float) -> void:
	if anchor:
		global_position = anchor.global_position
	if not is_drawing():
		rotation = PI if facing_left else 0.0

func set_facing(_facing_left: bool) -> void:
	facing_left = _facing_left
	scale.x = absf(scale.x)
	scale.y = -absf(scale.y) if facing_left else absf(scale.y)
	
func set_anchor(_anchor: Node2D) -> void:
	anchor = _anchor

func set_aim(direction: Vector2) -> void:
	hand_direction = direction
	
func reset() -> void:
	main_hand_state_machine.ChangeState(idle)
	if current_arrow:
		current_arrow.queue_free()
	current_arrow = null

func arrow_setup() -> void:
	set_hand_direction()
	
func draw_arrow() -> void:
	if !current_arrow:
		drawing_arrow.emit()
		var _arrow: Arrow = arrow.instantiate()
		var before_hit_abilities: Array = PlayerManager.player.get_abilities(PlayerAbility.TriggerType.BEFORE_HIT)
		var after_hit_abilities: Array = PlayerManager.player.get_abilities(PlayerAbility.TriggerType.AFTER_HIT)
		for ability in before_hit_abilities:
			_arrow.add_before_ability(ability)
		for ability in after_hit_abilities:

			_arrow.add_after_ability(ability)
		add_child(_arrow)
		var draw_abilities: Array[PlayerAbility] = PlayerManager.player.get_abilities(PlayerAbility.TriggerType.DRAW)
		_arrow.set_texture(arrow_texture)
		current_arrow = _arrow
		current_arrow.global_scale *= PlayerManager.player.stats.arrow_size.value()
		current_arrow.rotate(-PI/2)
		for ability in draw_abilities:
			ability.activate_ability(null, _arrow)
			if ability.has_method("draw_ended"):
				if !release.is_connected(ability.draw_ended):
					release.connect(ability.draw_ended)
		
func set_hand_direction() -> void:
	rotation = hand_direction.angle()
	if current_arrow:
		current_arrow.global_position = where_to_hold_arrow()
		
func where_to_hold_string() -> Vector2:
	return hold_position.global_position

func where_to_hold_arrow() -> Vector2:
	return arrow_position.global_position
	
func new_arrow(_arrow: PackedScene) -> void:
	if arrow.instantiate() is Arrow:
		arrow = _arrow

func release_arrow() -> void:
	var perfect_threshold_check: float
	if PlayerManager.player.stats.only_perfect:
		perfect_threshold_check = 0.99
	else:
		perfect_threshold_check = min_shot_power
	if shot_power < perfect_threshold_check and current_arrow:
		current_arrow.free()
	else:
		if current_arrow:
			EventBus.arrow_release_sound.emit(shot_power)
			current_arrow.arrow_shot_power = shot_power
			if shot_power >= 1.0:
				EventBus.camera_shake.emit(1.0,10.0)
				EventBus.apply_player_knockback.emit(-hand_direction,50)
				perfect_release_particles.emitting = true
			fire_arrow()
	current_arrow = null
	release.emit()

func fire_arrow(_override_arrow: Arrow = null, _override_direction: Vector2 = hand_direction, _override_power: float = shot_power) -> void:
	var source_arrow: Arrow = _override_arrow if _override_arrow else current_arrow
	var direction: Vector2 = _override_direction.normalized()
	var effective_power: float = lerpf(0.0, 1.0, pow(_override_power, weak_shot_punish))
	var arrow_count = PlayerManager.player.stats.arrow_count.value()
	var spread_angle = deg_to_rad(12.0)
	
	for i in arrow_count:
		var fired_arrow: Arrow
		if i == 0:
			fired_arrow = source_arrow
		else:
			fired_arrow = arrow.instantiate()
			fired_arrow.position = source_arrow.position
			
			fired_arrow.texture = source_arrow.sprite.texture
			
		fired_arrow.global_scale = source_arrow.global_scale

		@warning_ignore("narrowing_conversion")
		fired_arrow.possible_pierce = PlayerManager.player.stats.arrow_pierce.value()
		fired_arrow.can_pass_walls = PlayerManager.player.stats.can_pass_walls
		fired_arrow.crit_chance = PlayerManager.player.stats.crit_chance.value()
		var angle_offset: float = 0.0
		if arrow_count > 1:
			var t = (i / float(arrow_count - 1)) - 0.5
			angle_offset = t * spread_angle * (arrow_count - 1)
		
		var spread_direction = direction.rotated(angle_offset)
		
		if shot_power >= 1.0:
			fired_arrow.perfect_shot = true
		fired_arrow.arrow_shot_power = effective_power
		fired_arrow.velocity = calc_shot_velocity(effective_power, spread_direction)
		fired_arrow.fired = true
		fired_arrow.enabled = false
		fired_arrow.set_shot_power_mod(effective_power)
		fired_arrow.calc_dmg(effective_power)
		fired_arrow.calc_knockback(effective_power)
		#fired_arrow.shoot_abilities = PlayerManager.player.get_abilities(PlayerAbility.TriggerType.SHOOT)
		var release_abilities = PlayerManager.player.get_abilities(PlayerAbility.TriggerType.RELEASE)
		for ability in release_abilities:
			ability.activate_ability(null, fired_arrow)
		
		EventBus.summon_effect.emit(fired_arrow)
	EventBus.arrow_shot_sound.emit()
	PlayerManager.player.current_arrow = source_arrow
	
func draw_arrow_instance() -> Arrow:
	var _arrow: Arrow = arrow.instantiate()
	add_child(_arrow)
	_arrow.set_texture(arrow_texture)
	_arrow.global_scale *= PlayerManager.player.stats.arrow_size.value()
	return _arrow
	
func fire_at(_direction: Vector2, _power: float, _position: Vector2 = arrow_position.global_position) -> void:
	var _arrow: Arrow = draw_arrow_instance()
	_arrow.global_position = _position
	fire_arrow(_arrow, _direction, _power)
	
func calc_shot_velocity(_shot_power, direction) -> Vector2:
	var perfect_bonus = PlayerManager.player.stats.perfect_shot_bonus.value() if _shot_power >= 1.0 else 1.0
	var _shot_power_value: float = _shot_power
	if PlayerManager.player.stats.always_max_velocity:
		_shot_power_value = 1.0
	var final_value = _shot_power_value * perfect_bonus * direction * (PlayerManager.player.stats.arrow_speed.value())
	return final_value

func is_drawing() -> bool:
	return main_hand_state_machine.curr_state is PullingMainHandState or main_hand_state_machine.curr_state is MaxPullMainHandState

func start_draw() -> void:
	if is_idle():
		main_hand_state_machine.ChangeState(pulling)

func release_draw() -> void:
	if is_drawing():
		release_arrow()
		main_hand_state_machine.ChangeState(idle)

func set_time_for_perfect_shot(amount: float) -> void:
	if amount > 0:
		max_pull_state.perfect_shot_time = amount

func is_idle() -> bool:
	return main_hand_state_machine.curr_state is IdleMainHandState

func get_draw_stage() -> String:
	if main_hand_state_machine.curr_state is PullingMainHandState:
		return "Pull"
	if main_hand_state_machine.curr_state is MaxPullMainHandState:
		return "MaxPull"
	return ""

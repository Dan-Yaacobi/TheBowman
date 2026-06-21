class_name PlayerMainHand extends CharacterBody2D

signal shot_power_amount(amount)

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hold_position: Node2D = $HoldPosition
@onready var main_hand_state_machine: MainHandStateMachine = $MainHandStateMachine
@onready var max_pull_state: MaxPullMainHandState = $MainHandStateMachine/MaxPull
@onready var arrow_position: Node2D = $ArrowPosition
@onready var sprite: Sprite2D = $Sprite2D
@onready var swing_cooldown: Timer = $MainHandStateMachine/Swing/SwingCooldown

@export var arrow: PackedScene
@export var arrow_texture: Texture
@export var min_shot_power: float = 0.5
@export var max_offset: float

@onready var sword: Sword = $MainHandStateMachine/Swing/Sword

var current_arrow: Arrow = null
var hand_direction: Vector2
var pulling: bool = false
var shot_power: float
var off_hand: PlayerOffHand
var shot_offset: float = 0
var can_swing: bool = true

func _ready() -> void:
	main_hand_state_machine.Initialize(self)
	swing_cooldown.timeout.connect(swing_off_cooldown)
	pass
	
func _process(_delta: float) -> void:
	if PlayerManager.player.is_idle(): # and not GlobalPlayer.is_prev_jump():
		calculate_direction_to_cursor()
	pass

func connect_hands(_off_hand) -> void:
	if _off_hand:
		off_hand = _off_hand
		
func calculate_direction_to_cursor() -> void:
	var mouse_pos = get_global_mouse_position()
	var player_pos = global_position
	hand_direction = Vector2(mouse_pos[0] - player_pos[0],
	 mouse_pos[1] - player_pos[1])

	if mouse_pos.x > player_pos.x + 4:
		PlayerManager.player.update_direction(false)
	elif mouse_pos.x < player_pos.x - 4:
		PlayerManager.player.update_direction(true)

func set_swing_direction(_side: bool) -> void:
	if _side:
		if scale.x > 0:
			scale.x *= -1
	else:
		if scale.x < 0:
			scale.x *= -1

func arrow_setup() -> void:
	calculate_direction_to_cursor()
	set_hand_direction()
	
func draw_arrow() -> void:
	if !current_arrow:
		var _arrow: Arrow = arrow.instantiate()
		add_child(_arrow)
		_arrow.set_texture(arrow_texture)
		current_arrow = _arrow

func set_hand_direction() -> void:
	rotation = hand_direction.angle() - PI/2
	if current_arrow:
		current_arrow.global_position = where_to_hold_arrow()
		
func where_to_hold_string() -> Vector2:
	return hold_position.global_position

func where_to_hold_arrow() -> Vector2:
	return arrow_position.global_position
	
func change_direction() -> void:
	scale.x *= - 1
	position.x *= - 1

func new_arrow(_arrow: PackedScene) -> void:
	if arrow.instantiate() is Arrow:
		arrow = _arrow

func release_arrow() -> void:
	PlayerManager.player.set_shooting(false)
	if shot_power < 0.2:
		current_arrow.free()
	else:
		if current_arrow:
			current_arrow.arrow_shot_power = shot_power
			current_arrow.shoot_abilities = PlayerManager.player.get_abilities(PlayerAbility.TriggerType.SHOOT)
			fire_arrow()
	current_arrow = null

func fire_arrow() -> void:
	var direction = hand_direction.normalized()
	var effective_power: float = lerpf(0.0, 1.0, pow(shot_power, 0.5))
	var arrow_count = PlayerManager.player.stats.arrow_count.value()
	var spread_angle = deg_to_rad(12.0)
	
	for i in arrow_count:
		var fired_arrow: Arrow
		if i == 0:
			fired_arrow = current_arrow
		else:
			fired_arrow = arrow.instantiate()
			fired_arrow.position = current_arrow.position
			get_tree().root.add_child(fired_arrow)
			fired_arrow.global_scale = current_arrow.global_scale
			fired_arrow.set_texture(arrow_texture)
			
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
		fired_arrow.velocity = calc_shot_velocity(effective_power, spread_direction)
		fired_arrow.fired = true
		fired_arrow.set_shot_power_mod(effective_power)
		fired_arrow.enable_arrow()
		fired_arrow.calc_dmg(effective_power)
		fired_arrow.calc_knockback(effective_power)
		fired_arrow.shoot_abilities = PlayerManager.player.get_abilities(PlayerAbility.TriggerType.SHOOT)
		var release_abilities = PlayerManager.player.get_abilities(PlayerAbility.TriggerType.RELEASE)
		for ability in release_abilities:
			ability.activate_ability(null, fired_arrow)
		if i != 0:
			fired_arrow.reparent(get_tree().root)
		else:
			current_arrow.reparent(get_tree().root)
	EventBus.arrow_shot_sound.emit()
	PlayerManager.player.current_arrow = current_arrow
	
	
func calc_shot_velocity(_shot_power, direction) -> Vector2:
	var perfect_bonus = PlayerManager.player.stats.perfect_shot_bonus.value() if _shot_power >= 1.0 else 1.0
	var final_value = _shot_power * perfect_bonus * direction * (PlayerManager.player.stats.arrow_speed.value())
	return final_value


func swing_off_cooldown() -> void:
	can_swing = true
	
func is_swinging() -> bool:
	return main_hand_state_machine.curr_state is SwingMainHandState

func set_time_for_perfect_shot(amount: float) -> void:
	if amount > 0:
		max_pull_state.perfect_shot_time = amount

func is_idle() -> bool:
	return main_hand_state_machine.curr_state is IdleMainHandState
	

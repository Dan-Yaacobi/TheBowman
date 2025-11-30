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
@export var min_shot_power: float = 0.5
@export var max_offset: float

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
		arrow_position.add_child(_arrow)
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
	position.x *= - 1

func new_arrow(_arrow: PackedScene) -> void:
	if arrow.instantiate() is Arrow:
		arrow = _arrow
		
func release_arrow() -> void:
	PlayerManager.player.set_shooting(false)
	#PlayerManager.player.shake_screen.emit(shot_power)
	if shot_power * PlayerManager.player.get_pull_speed() >= min_shot_power:
		#PlayerManager.player.apply_recoil(shot_power * 50)
		## if shot power is 1: max pull, if shot_offset = 0: released within perfect shot window
		for shoot_ability in PlayerManager.player.get_shoot_abilities():
			if shoot_ability:
				shoot_ability.activate_ability(current_arrow)
		fire_arrow()
	else:
		current_arrow.free()
	current_arrow = null
	
func fire_arrow() -> void:
	var direction = hand_direction.normalized() # calc_offset_direction(hand_direction,shot_offset).normalized()
	if shot_power == 1:# and shot_offset == 0:
		current_arrow.perfect_shot = true
	current_arrow.velocity = calc_shot_velocity(shot_power,direction)
	current_arrow.fired = true
	#current_arrow.set_ability(PlayerManager.player.get_arrow_ability())
	current_arrow.set_shot_power_mod(shot_power)
	current_arrow.enable_arrow()
	#current_arrow.arrow_shot()
	current_arrow.calc_dmg(shot_power)
	current_arrow.reparent(get_tree().root)
	EventBus.arrow_shot_sound.emit()
	PlayerManager.player.current_arrow = current_arrow
	
func calc_shot_velocity(_shot_power,direction) -> Vector2:
	return _shot_power * direction *( PlayerManager.player.get_strength_shot_modifier() + current_arrow.data.speed)

#func set_offset(amount: float) -> void:
	#shot_offset = amount * 5
	
#func calc_offset_direction(og_direction: Vector2, offset: float) -> Vector2:
	#var res: Vector2
	#var rand_dir: int = [1,-1].pick_random()
	#if abs(og_direction.x) > abs(og_direction.y):
		#res = Vector2(og_direction.x, og_direction.y + rand_dir * offset)
	#else:
		#res = Vector2(og_direction.x + rand_dir * offset, og_direction.y)
	#return res

func swing_off_cooldown() -> void:
	can_swing = true
	
func is_swinging() -> bool:
	return main_hand_state_machine.curr_state is SwingMainHandState

func set_time_for_perfect_shot(amount: float) -> void:
	if amount > 0:
		max_pull_state.perfect_shot_time = amount

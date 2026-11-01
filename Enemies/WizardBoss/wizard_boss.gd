class_name WizardBoss extends Boss

@export var element_color: Color = Color(1.0, 0.45, 0.1)
## How fast the hand glow fades in and out (glow amount per second)
@export var cast_glow_speed: float = 6.0
@export var teleport_points: Array[Marker2D]
@export var spell_rotation: Array[WizardSpellState]
@export var markers: Array[NamedMarker]
## Parent of the arena's islands; spells that target islands read its children
@export var island_root: Node2D
@export var item_drop: EquipmentData
@export var total_essence_drop: int
## When true, the wizard keeps his current facing (e.g. during a directional spell)
var lock_facing: bool = false
## Active damage-blocking shell, if any (set by the shell itself)
var shield: FrostShell
var current_point: Marker2D
var _spell_index: int = 0
var _shader: ShaderMaterial
var _glow: float = 0.0
var _glow_target: float = 0.0

func extra_ready_functions() -> void:
	animation_player = $AnimationPlayer
	_shader = sprite.material as ShaderMaterial

## Hand glow while casting (0 = off, 1 = full). It fades toward this value.
func set_cast_glow(amount: float) -> void:
	_glow_target = clampf(amount, 0.0, 1.0)

# _process (not physics) so the glow still fades out while he is frozen or stunned
func _process(delta: float) -> void:
	if _shader == null or is_equal_approx(_glow, _glow_target):
		return
	_glow = move_toward(_glow, _glow_target, cast_glow_speed * delta)
	_shader.set_shader_parameter("glow_amount", _glow)

func _physics_process(_delta: float) -> void:
	if not lock_facing:
		face_the_player()

# Sprite faces right by default, so flip when the player is to the left
func face_the_player() -> void:
	sprite.flip_h = PlayerManager.player.global_position.x < global_position.x

# Signals fire immediately (health bar, portal); the dead state frees him after the animation
func enemy_died() -> void:
	died.emit(self)
	EventBus.enemy_died.emit(self)
	if dead_state == null:
		queue_free()
		return
	if stunned:
		end_stun()
	state_machine.ChangeState(dead_state)

func _on_fight_began() -> void:
	state_machine.Initialize(self)

## Next spell in the rotation, skipping any that can't be cast right now
func next_spell() -> WizardSpellState:
	for i: int in spell_rotation.size():
		var spell: WizardSpellState = spell_rotation[_spell_index]
		_spell_index = (_spell_index + 1) % spell_rotation.size()
		if spell and spell.can_cast():
			return spell
	return null

func has_shield() -> bool:
	return is_instance_valid(shield)

# While shielded, hits crack the shield instead of hurting him
func hit(_hurt_box: HurtBox, _result: DamageResult) -> void:
	if has_shield():
		shield.absorb_hit(_hurt_box)
		take_hit_effect()
		return
	super(_hurt_box, _result)

# Also blocks damage that doesn't come from a direct hit (e.g. burn ticks)
func _handle_take_damage(_hurt_box: HurtBox, raw_damage, _result: DamageResult = null, _alter_dmg_color: Color = Color.RED) -> void:
	if has_shield():
		return
	super(_hurt_box, raw_damage, _result, _alter_dmg_color)

## Cancels the spell he is casting (if any) and sends him back to idle
func interrupt_spell() -> void:
	var spell: WizardSpellState = state_machine.curr_state as WizardSpellState
	if spell and spell.idle_state:
		state_machine.ChangeState(spell.idle_state)

func set_targetable(value: bool) -> void:
	hit_box.set_deferred("monitorable", value)
	hurt_box.set_deferred("monitoring", value)

## 0 = fully visible, 1 = fully faded out
func set_fade(value: float) -> void:
	sprite.modulate.a = 1.0 - value

func get_marker(marker_id: StringName) -> NamedMarker:
	for m: NamedMarker in markers:
		if m.id == marker_id:
			return m
	return null

func get_islands() -> Array[Island]:
	var islands: Array[Island] = []
	if island_root == null:
		return islands
	for child: Node in island_root.get_children():
		if child is Island:
			islands.append(child)
	return islands

func drop_item() -> void:
	if item_drop:
		EventBus.drop_specific_item.emit(item_drop,global_position, 2)
	EventBus.try_drop.emit(global_position,100, 1)	
	EventBus.drop_item.emit(CustomVariables.items.ESSENCE,global_position,100,total_essence_drop)

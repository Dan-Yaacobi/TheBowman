class_name Debuff extends Node2D

signal debuff_over(id: int)

@export var ID: int
@export var can_stack: bool = true

var time_accumulator: float
var tick_interval: float
var ticks: int = 0
var one_shot: bool = false
var entity: GameEntity

## Where a status effect sits on the host sprite. BEHIND_FEET draws behind it (burn).
enum StatusSpot { CENTER, FEET, HEAD, BEHIND_FEET }

var _status_sprite: EffectSprite

func _ready() -> void:
	start_debuff_effect()
	_attach_status_sprite()

## EffectSheet name for this debuff's looping status effect (empty = none).
func status_sheet_name() -> StringName:
	return &""

func status_spot() -> StatusSpot:
	return StatusSpot.CENTER

## Debuffs live on the entity's sprite; the status effect goes on that sprite's outline,
## and the debuff's old particle visuals are hidden while the new effects are on.
func _attach_status_sprite() -> void:
	var sheet_name: StringName = status_sheet_name()
	if sheet_name == &"" or not EffectSprite.enabled:
		return
	for child: Node in get_children():
		if child is CanvasItem:
			(child as CanvasItem).visible = false
	var rect: Rect2 = host_rect()
	var at: Vector2 = rect.get_center()
	match status_spot():
		StatusSpot.FEET, StatusSpot.BEHIND_FEET:
			at.y = rect.end.y
		StatusSpot.HEAD:
			at.y = rect.position.y
	_status_sprite = EffectSprite.attach(sheet_name, self, at)
	if _status_sprite and status_spot() == StatusSpot.BEHIND_FEET:
		_status_sprite.z_index = -1

## The host sprite's visible body in its own coordinates, trimmed in from the frame edges
## (sprites have empty padding around the creature).
func host_rect() -> Rect2:
	var host: Sprite2D = get_parent() as Sprite2D
	if host == null or host.texture == null:
		return Rect2(-12, -12, 24, 24)
	var rect: Rect2 = host.get_rect()
	return rect.grow_individual(-rect.size.x * 0.2, -rect.size.y * 0.2, -rect.size.x * 0.2, -rect.size.y * 0.15)
	
func apply_debuff_effect() -> void:
	pass

func start_debuff_effect() -> void:
	pass
	
func _process(delta: float) -> void:
	time_accumulator += delta
	if time_accumulator >= tick_interval:
		time_accumulator -= tick_interval
		if not one_shot:
			apply_debuff_effect()
		ticks -= 1
		if ticks <= 0:
			debuff_end()
			
func debuff_end() -> void:
	debuff_over.emit(ID)
	extra_end_debuff_methods()
	queue_free()

func extra_end_debuff_methods() -> void:
	pass
	
func merge(_incoming: Debuff, _incoming_ticks: int) -> void:
	ticks += _incoming_ticks

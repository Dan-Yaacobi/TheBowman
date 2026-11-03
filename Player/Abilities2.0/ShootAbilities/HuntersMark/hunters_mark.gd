class_name HuntersMark extends Node2D
## Mark stacks on one enemy: a sigil above it with one pip per stack. Owned by the enemy, so it dies with it.

const SIGIL_PATH: String = "res://Player/Abilities2.0/ShootAbilities/HuntersMark/Sprites/HuntersMarkSigil.png"
const PIP_COLOR: Color = Color(0.95, 0.25, 0.15)
const PIP_EMPTY_COLOR: Color = Color(0.15, 0.08, 0.06, 0.6)

var stacks: int = 0
var spent: bool = false
var max_stacks: int = 5
var _sigil: Sprite2D

## Returns the enemy's mark, creating it if needed.
static func on(enemy: Enemy) -> HuntersMark:
	for child in enemy.get_children():
		if child is HuntersMark and not child.spent:
			return child
	var mark: HuntersMark = HuntersMark.new()
	var height: float = 16.0
	if enemy.hit_box and enemy.hit_box.collision and enemy.hit_box.collision.shape:
		height = enemy.hit_box.collision.shape.get_rect().size.y * enemy.hit_box.collision.global_scale.y / maxf(enemy.global_scale.y, 0.01)
	mark.position = Vector2(0, -height * 0.5 - 14.0)
	enemy.add_child(mark)
	return mark

static func find(enemy: Enemy) -> HuntersMark:
	for child in enemy.get_children():
		if child is HuntersMark and not child.spent:
			return child
	return null

func _ready() -> void:
	z_index = 5
	_sigil = Sprite2D.new()
	_sigil.texture = load(SIGIL_PATH)
	add_child(_sigil)

func add_stack() -> void:
	stacks = mini(stacks + 1, max_stacks)
	var tween: Tween = create_tween()
	_sigil.scale = Vector2(1.4, 1.4)
	tween.tween_property(_sigil, "scale", Vector2.ONE, 0.15)
	queue_redraw()

## Spends every stack with a pop, then removes the mark.
func consume() -> int:
	var used: int = stacks
	stacks = 0
	spent = true
	queue_redraw()
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(_sigil, "scale", Vector2(2.2, 2.2), 0.18)
	tween.tween_property(self, "modulate:a", 0.0, 0.18)
	tween.chain().tween_callback(queue_free)
	return used

func _draw() -> void:
	var spacing: float = 3.0
	var start_x: float = -(max_stacks - 1) * spacing / 2.0
	for i in max_stacks:
		draw_rect(Rect2(start_x + i * spacing - 1.0, 7.0, 2.0, 2.0), PIP_COLOR if i < stacks else PIP_EMPTY_COLOR)

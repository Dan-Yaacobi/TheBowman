class_name EquipmentSlot extends Panel

const EMPTY_BORDER: Color = Color(0.36, 0.42, 0.53)
const BORDER_WIDTH: int = 3

@onready var slot_texture: TextureRect = $SlotTexture
@onready var slot_label: Label = $SlotLabel

func refresh(equipment: EquipmentData, label: String) -> void:
	slot_label.text = label
	slot_texture.texture = equipment.texture if equipment else null
	var border: Color = CustomVariables.rarity_color(equipment.rarity) if equipment else EMPTY_BORDER
	add_theme_stylebox_override("panel", _make_box(border))

func _make_box(border: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = Color(0.105, 0.137, 0.2, 0.9)
	box.border_color = border
	box.set_border_width_all(BORDER_WIDTH)
	box.set_corner_radius_all(4)
	return box

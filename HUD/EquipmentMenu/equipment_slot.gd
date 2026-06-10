class_name EquipmentSlot extends Button

@onready var slot_texture: TextureRect = $HBoxContainer/SlotTexture
@onready var slot_label: Label = $HBoxContainer/SlotLabel

func refresh(equipment: EquipmentData, label: String) -> void:
	if equipment == null:
		slot_texture.texture = null
		slot_label.text = label + "\n[empty]"
		modulate = Color.WHITE
	else:
		slot_texture.texture = equipment.texture
		slot_label.text = label + "\n" + equipment.display_name
		modulate = CustomVariables.rarity_color(equipment.rarity)

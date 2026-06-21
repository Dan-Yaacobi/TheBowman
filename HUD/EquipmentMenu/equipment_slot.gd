class_name EquipmentSlot extends Button

@onready var slot_texture: TextureRect = $VBoxContainer/SlotTexture
@onready var slot_label: Label = $VBoxContainer/SlotLabel

func refresh(equipment: EquipmentData, label: String) -> void:

	if equipment == null:
		slot_texture.texture = null
		slot_label.text = label + ":" + "[empty]"
		modulate = Color.WHITE	
	else:
		await get_tree().process_frame
		slot_texture.texture = equipment.texture
		slot_label.text = equipment.display_name
		#modulate = CustomVariables.rarity_color(equipment.rarity)

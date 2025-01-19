class_name DropData extends Resource

@export var item_data: ItemData
@export_range(0,100,1,"suffix:%") var probability: float = 100

func drop_chance() -> bool:
	if randi_range(0,100) >= probability:
		return false
	return true

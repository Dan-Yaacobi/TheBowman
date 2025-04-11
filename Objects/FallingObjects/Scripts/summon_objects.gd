class_name SummonObjects extends Resource

const TREASURE_CHEST = preload("res://Objects/FallingObjects/Objects/TreasureChest/TreasureChest.tscn")
var objects: Array[PackedScene] = [TREASURE_CHEST]

func get_object(_player: Player) -> FallingObject:
	var object: FallingObject = objects.pick_random().instantiate()
	object.set_player(_player)
	return object

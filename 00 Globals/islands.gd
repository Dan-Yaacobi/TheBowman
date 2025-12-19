extends Node

const ISLAND = preload("uid://bnq5ivogfkh6w")
const ISLAND_2 = preload("uid://djpo5x6fupy0e")
const ISLAND_3 = preload("uid://crgxmsjdnkrt4")
const ISLAND_4 = preload("uid://b506vw0hbtcju")
const ISLAND_5 = preload("uid://l2y4uh7pm6ak")


var islands: Array[PackedScene] = [
	ISLAND,ISLAND_2,ISLAND_3,ISLAND_4,ISLAND_5
]

func get_island() -> Island:
	var new_island: Island = islands.pick_random().instantiate()
	new_island.floating = [true,false].pick_random()
	return new_island

extends Node
enum worlds {Main_Menu=1,Rift_1=2,NextRift=3}

const MAIN_MENU = preload("uid://cnhbrpo4htp2y")
const RIFT = preload("uid://iitxisrr6wi5")

const worlds_dic = {
 	worlds.Main_Menu: MAIN_MENU,
	worlds.Rift_1: RIFT,
	}

func get_world(_new_world: worlds) -> GameWorld:
	if not worlds_dic.has(_new_world):
		push_error("No world registered for %s" % worlds.keys()[_new_world])
		return null
	var scene: PackedScene = worlds_dic[_new_world]
	if scene == null:
		push_error("World scene is null for %s (cyclic preload?)" % worlds.keys()[_new_world])
		return null
	var node: Node = scene.instantiate()
	if not node is GameWorld:
		push_error("Root of %s is %s, not a GameWorld" % [scene.resource_path, node.get_class()])
		node.queue_free()
		return null
	return node

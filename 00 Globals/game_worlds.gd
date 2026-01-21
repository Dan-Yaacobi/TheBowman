extends Node
enum worlds {Bow_Shop,Main_Menu,Rift_1}

const BOWS_SHOP = preload("uid://cmdeim0mrcv32")
const MAIN_MENU = preload("uid://cnhbrpo4htp2y")
const RIFT = preload("uid://iitxisrr6wi5")

const worlds_dic = {
	worlds.Bow_Shop: BOWS_SHOP,
 	worlds.Main_Menu: MAIN_MENU,
	worlds.Rift_1: RIFT
	}

func get_world(_new_world: worlds) -> GameWorld:
	if worlds_dic.has(_new_world):
		return worlds_dic[_new_world].instantiate()
	return null

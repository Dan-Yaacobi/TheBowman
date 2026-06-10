extends Node
const BARREL = preload("uid://dgg5cogy6ysqm")
const CRATE = preload("uid://cyqdfqcoqypvx")
const LIGHT_POST = preload("uid://tyfgom2bccki")
const VASE = preload("uid://bn3sgk18054s0")
const FLOWERS_1 = preload("uid://wof3tik1c2jy")
const FLOWERS_2 = preload("uid://clkrvisq3ps4h")
const MUSHROOMS_1 = preload("uid://ypqruw7ef61")
const ROCKS_1 = preload("uid://dfyy18crd3gd0")
const ROCKS_2 = preload("uid://453b1cwdxo20")

var objects: Array[PackedScene] = [BARREL,CRATE,LIGHT_POST,VASE,FLOWERS_1,FLOWERS_2,MUSHROOMS_1
,ROCKS_1,ROCKS_2]

func get_random_object() -> PackedScene:
	return objects.pick_random()

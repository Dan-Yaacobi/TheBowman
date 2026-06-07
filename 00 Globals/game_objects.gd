extends Node
const BARREL = preload("uid://dgg5cogy6ysqm")
const CRATE = preload("uid://cyqdfqcoqypvx")
const LIGHT_POST = preload("uid://tyfgom2bccki")
const VASE = preload("uid://bn3sgk18054s0")

var objects: Array[PackedScene] = [BARREL,CRATE,LIGHT_POST,VASE]

func get_random_object() -> PackedScene:
	return objects.pick_random()

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
const DECORATION = preload("uid://cq1lw1j5im8pg")

## Objects islands can spawn, with their spawn weights (higher = more common).
## Gold vases are a rare treat.
var objects: Array[PackedScene] = [BARREL, CRATE, DECORATION, VASE]
var object_weights: PackedFloat32Array = [1.0, 1.0, 1.0, 0.2]

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()

func get_random_object() -> PackedScene:
	return objects[_rng.rand_weighted(object_weights)]

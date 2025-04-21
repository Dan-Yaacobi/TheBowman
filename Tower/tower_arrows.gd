class_name TowerArrows extends Node2D
const BASIC_ARROW = preload("res://Weapons/0_BasicBow/BasicArrow/BasicArrow.tscn")
const BLUE_ARROW = preload("res://Weapons/1_BlueBow/BlueArrow/BlueArrow.tscn")
const RED_ARROW = preload("res://Weapons/2_RedBow/RedArrow/RedArrow.tscn")
const BLACK_ARROW = preload("res://Weapons/3_BlackBow/BlackArrow/BlackArrow.tscn")
const NATURE_ARROW = preload("res://Weapons/4_NatureBow/NatureArrow/NatureArrow.tscn")
const THUNDER_ARROW = preload("res://Weapons/5_ThunderBow/ThunderArrow/ThunderArrow.tscn")
const BONE_BOW = preload("res://Weapons/6_BoneBow/BoneBow.tscn")
const BUBBLE_GUM = preload("res://Weapons/7_BubbleGumBow/BubbleGum/BubbleGum.tscn")

const ARROWS: Array[PackedScene] = [BASIC_ARROW,BLUE_ARROW,RED_ARROW,BLACK_ARROW,
NATURE_ARROW,THUNDER_ARROW,BONE_BOW,BUBBLE_GUM]

func get_arrow(level: int) -> PackedScene:
	return ARROWS[level]

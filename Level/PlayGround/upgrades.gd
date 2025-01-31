class_name UpgradeBuckets extends Node2D

var bucket1_upgrades: Array[PlayerUpgrade]
var bucket2_upgrades: Array[PlayerUpgrade]
var bucket3_upgrades: Array[PlayerUpgrade]

var bucket1_used_upgrades: Array[PlayerUpgrade]
var bucket2_used_upgrades: Array[PlayerUpgrade]
var bucket3_used_upgrades: Array[PlayerUpgrade]

var bucket1_abilities_chosen: Array[PlayerUpgrade]
var bucket2_abilities_chosen: Array[PlayerUpgrade]
var bucket3_abilities_chosen: Array[PlayerUpgrade]

var buckets: Dictionary = {1 : bucket1_upgrades, 2 : bucket2_upgrades , 3 : bucket3_upgrades}
var used_buckets: Dictionary = {1 : bucket1_used_upgrades, 2 : bucket2_used_upgrades , 3 : bucket3_used_upgrades}
var abilities_bucket: Dictionary = {1:bucket1_abilities_chosen,2:bucket2_abilities_chosen,3:bucket3_abilities_chosen}

var total_buckets: int = 3

func _ready() -> void:
	refill_buckets()

func get_bucket_upgrade(bucket: int) -> PlayerUpgrade:
	if bucket == 0:
		return null
	if buckets[bucket].size() == 0:
		return get_bucket_upgrade(bucket - 1)
	var choose_upgrade: PlayerUpgrade = buckets[bucket].pick_random()
	buckets[bucket].erase(choose_upgrade)
	used_buckets[bucket].append(choose_upgrade)
	return choose_upgrade

func refill_buckets() -> void:
	reset_buckets()
	for child in get_children():
		
		if child.name == "Bucket1":
			for upgrade in child.get_children():
				if upgrade not in bucket1_abilities_chosen:
					bucket1_upgrades.append(upgrade)
					
		if child.name == "Bucket2":
			for upgrade in child.get_children():
				if upgrade not in bucket2_abilities_chosen:
					bucket2_upgrades.append(upgrade)
					
		if child.name == "Bucket3":
			for upgrade in child.get_children():
				if upgrade not in bucket3_abilities_chosen:
					bucket3_upgrades.append(upgrade)
	
func reset_buckets() -> void:
	for key in used_buckets.keys():
		used_buckets[key].clear()
	for key in buckets.keys():
		buckets[key].clear()

func big_reset() -> void:
	for ability in bucket1_abilities_chosen:
		bucket1_upgrades.append(ability)
		bucket1_abilities_chosen.erase(ability)
		
	for ability in bucket2_abilities_chosen:
		bucket2_upgrades.append(ability)
		bucket2_abilities_chosen.erase(ability)
		
	for ability in bucket3_abilities_chosen:
		bucket3_upgrades.append(ability)
		bucket3_abilities_chosen.erase(ability)
	pass
	

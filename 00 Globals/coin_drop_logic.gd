extends Node

const COIN = preload("res://Items/Coin.tres")
const DIAMOND = preload("res://Items/Diamond.tres")
const RED_DIAMOND = preload("res://Items/RedDiamond.tres")

## Given an amount of money, returns an array of item data of drops. 
## The lvl defines the range of the outcome. 
## For example: amount = 10, lvl = 3 means the range will be 7 - 13.
func drop_logic(amount: int, lvl: int = 3) -> Array[ItemData]:
	var drops: Array[ItemData]
	if amount <= 0:
		return drops
		
	var bonus = PlayerManager.player.get_gold_bonus()
	var final_amount: int = randi_range(max(bonus,amount - lvl + bonus), amount + lvl + bonus)	
	var red_diamonds: int = floor(final_amount / RED_DIAMOND.value)
	var diamonds: int = floor((final_amount - red_diamonds*RED_DIAMOND.value) /DIAMOND.value)
	var coins: int = final_amount - red_diamonds*RED_DIAMOND.value - diamonds*DIAMOND.value
	
	for i in range(red_diamonds):
		drops.append(RED_DIAMOND)
	for i in range(diamonds):
		drops.append(DIAMOND)
	for i in range(coins):
		drops.append(COIN)
	return drops

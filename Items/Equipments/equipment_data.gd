class_name EquipmentData extends Resource

enum slots{BOW,ARROW,RING}

class StatModifier:
	static var next_id: int = 0
	var id: int
	var stat_name: String
	var amount: float
	var stat_type: Stat.buff_type
	var display_name: String
	
	func _init(_amount: float, _stat_name: String, _type: Stat.buff_type) -> void:
		id = StatModifier.next_id
		StatModifier.next_id += 1
		amount = _amount
		stat_name = _stat_name
		stat_type = _type

@export var display_name: String
@export var texture: Texture2D
@export var rarity: float
@export var equipped_texture: Texture2D
@export var equipped_scale: Vector2 = Vector2(1,1)

var ability: PlayerAbility = null
var dropped_scale: float
var equipment_scene: PackedScene
var slot: slots
var modifiers: Array = []

func add_modifier(stat_name: String, amount: float, _type: Stat.buff_type) -> void:
	modifiers.append(StatModifier.new(amount, stat_name, _type))
	
func equip(player_stats: PlayerStats) -> void:
	for mod in modifiers:
		var stat: Stat = player_stats.get(mod.stat_name)
		if stat == null:
			push_error("Unknown stat: " + mod.stat_name)
			continue
		stat.add_buff(mod.id, mod.amount, mod.stat_type)
	if ability:
		PlayerManager.player.register_ability(ability)
		
func unequip(player_stats: PlayerStats) -> void:
	for mod in modifiers:
		var stat: Stat = player_stats.get(mod.stat_name)
		if stat == null:
			push_error("Unknown stat: " + mod.stat_name)
			continue
		stat.remove_buff_completly(mod.id, mod.stat_type)
	if ability:
		PlayerManager.player.unregister_ability(ability)

class_name SpiritBoon extends Resource
## A one-run blessing from the world spirit. After every death the spirit offers 3 rolled from
## MetaProgress.boon_pool; the picked one applies when the next run's first rift starts.

enum Kind { STAT, HEART, ITEM }

## Saved in the save file. Never rename once players have saves.
@export var id: StringName
@export var title: String
@export_multiline var description: String
@export var icon: Texture2D
@export var kind: Kind = Kind.STAT
@export var title_color: Color = Color.WHITE

@export_group("Stat")
## A Stat on PlayerStats, e.g. arrow_damage.
@export var stat_name: StringName
## 0.15 with MULTIPLICATIVE = +15%.
@export var amount: float = 0.15
@export var buff_type: Stat.buff_type = Stat.buff_type.MULTIPLICATIVE

@export_group("Item")
@export var item_slot: LootManager.Slot = LootManager.Slot.BOW
## Distance in front of the player the item lands.
@export var drop_offset: float = 24.0
@export_group("")


func apply(player: Player, buff_id: int) -> void:
	match kind:
		Kind.STAT:
			var stat: Stat = _get_stat(player)
			if stat:
				stat.add_buff(buff_id, amount, buff_type)
		Kind.HEART:
			# Run-only heart container; the dead state clears extra_hp on death.
			player.increase_max_hp(true)
		Kind.ITEM:
			var loot: LootManager = GameStateManager.current_loot_manager
			if loot == null:
				return
			var data: EquipmentData = loot.drop_equipment(item_slot)
			if data:
				var spot: Vector2 = player.global_position + Vector2(player.body.facing_direction * drop_offset, 0.0)
				EventBus.equipment_dropped.emit(data, spot, null)


func remove(player: Player, buff_id: int) -> void:
	if kind != Kind.STAT:
		return
	var stat: Stat = _get_stat(player)
	if stat:
		stat.remove_buff_completly(buff_id, buff_type)


func _get_stat(player: Player) -> Stat:
	var stat: Stat = player.stats.get(stat_name) as Stat
	if stat == null:
		push_warning("SpiritBoon '%s': '%s' is not a Stat on PlayerStats" % [id, stat_name])
	return stat

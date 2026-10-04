#extends Node
#
#var active: Array[ActiveQuest] = []
#
#func _ready() -> void:
	#EventBus.enemy_killed.connect(_on_enemy_killed)
	#EventBus.altar_completed.connect(func() -> void: report(&"altar_completed", {}))
#
#func _on_enemy_killed(enemy: EnemyData, item_id: StringName) -> void:
	#report(&"enemy_killed", {"enemy_id": enemy.id, "item_id": item_id})
#
#func report(type: StringName, data: Dictionary) -> void:
	#for quest: ActiveQuest in active:
		#if quest.is_complete() or not quest.def.objective.matches(type, data):
			#continue
		#quest.progress += 1
		#EventBus.quest_progressed.emit(quest)
		#if quest.is_complete():
			#_complete(quest)

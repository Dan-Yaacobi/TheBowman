class_name LockCurse extends ChallengeCurse

enum Lock { DASH, SWORD }

@export var lock: Lock

func apply(_challenge: ChallengeStoneEvent) -> void:
	_change_lock(1)

func remove(_challenge: ChallengeStoneEvent) -> void:
	_change_lock(-1)

func _change_lock(amount: int) -> void:
	var player: Player = PlayerManager.player
	match lock:
		Lock.DASH:
			player.can_dash += amount
		Lock.SWORD:
			player.main_hand.can_swing += amount

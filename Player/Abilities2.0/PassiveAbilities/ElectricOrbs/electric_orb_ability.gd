class_name ElectricOrbAbility extends PlayerPassiveAbility

const ORB_CONTROLLER = preload("uid://clp03ayegk4n6")

var orb_reference: OrbController

func on_equipped() -> void:
	var new_orb: OrbController = ORB_CONTROLLER.instantiate()
	orb_reference = new_orb
	PlayerManager.player.add_child(new_orb)

func on_unequipped() -> void:
	orb_reference.queue_free()

func get_tooltip() -> String:
	return "Summons 3 Orbs around you every 5 seconds that stun enemies"

func get_tooltip_color() -> Color:
	return Color.ORANGE

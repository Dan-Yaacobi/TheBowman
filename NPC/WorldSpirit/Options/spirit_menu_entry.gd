class_name SpiritMenuEntry extends RefCounted
## One line in the spirit's options menu. Built by a SpiritOption; the option gets it back in run().

var label: String = ""
## Higher sorts first. The first entry is selected when the menu opens.
var priority: int = 0
## Turn-ins light the spirit's "!" and keep the menu open after an option finishes.
var is_turn_in: bool = false
## Anything the option needs to remember about this entry (e.g. which lore item).
var payload: Variant = null
## Set by WorldSpirit when it collects entries.
var option: SpiritOption = null

func _init(entry_label: String, entry_priority: int, entry_is_turn_in: bool, entry_payload: Variant = null) -> void:
	label = entry_label
	priority = entry_priority
	is_turn_in = entry_is_turn_in
	payload = entry_payload

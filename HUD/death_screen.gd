class_name DeathScreen extends Control
@onready var tally: Label = $Tally
@onready var rift_level: Label = $RiftLevel

func _ready() -> void:
	visible = false
	EventBus.player_died.connect(death_screen)

func death_screen() -> void:
	tally.text = "Total Enemies Killed: " + str(PlayerManager.player.enemies_killed)
	rift_level.text = "You have reached rift level " + str(PlayerManager.player.stats.rift_level)
	modulate.a = 0.0
	visible = true
	get_tree().paused = true
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
	
func _on_button_pressed() -> void:
	get_tree().paused = false
	PlayerManager.player.enemies_killed = 0
	visible = false

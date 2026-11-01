class_name FrostShellSpell extends WizardSpellState
## Wraps the wizard in an ice shell right where he stands (set teleport_before off on this node).
## The shell lasts until it is broken, so this spell skips its turn while one is up.

@export var shell_scene: PackedScene

func can_cast() -> bool:
	var boss: WizardBoss = enemy as WizardBoss
	return boss != null and not boss.has_shield()

func on_cast_start() -> void:
	if shell_scene == null or wizard.has_shield():
		return
	var shell: FrostShell = shell_scene.instantiate()
	# Lives on the sprite so it fades with him during teleports and moves with him
	wizard.sprite.add_child(shell)
	shell.attach(wizard)

class_name RunNodeData extends Resource
## One kind of node a crossroads portal can lead to.

enum Type { COMBAT, ELITE, EVENT, REST }

@export var display_name: String = ""
@export var type: Type = Type.COMBAT
## The GameWorld scene played for this node.
@export var scene: PackedScene
## Biomes this node can show up in. None ticked = every biome.
@export_flags("Dirt", "Snow", "Hell") var biomes: int = 0

@export_group("Telegraph")
## 0 = safe (rest) .. 3 = very dangerous. Drives portal size and particle density.
@export_range(0, 3) var danger: int = 1
## Shown above the portal. Placeholder until reward icons exist.
@export var icon: Texture2D
## Shown above the portal when there's no icon.
@export var icon_text: String = ""
@export var portal_color: Color = Color.WHITE


func appears_in(biome: int) -> bool:
	return biomes == 0 or (biomes & (1 << biome)) != 0

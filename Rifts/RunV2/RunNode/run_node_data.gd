class_name RunNodeData extends Resource
## One kind of node a crossroads portal can lead to.

enum Type { COMBAT, ELITE, EVENT, REST }

@export var display_name: String = ""
@export var type: Type = Type.COMBAT
## The GameWorld scene played for this node.
@export var scene: PackedScene
## Placeholder telegraph until danger particles and reward icons exist.
@export var portal_color: Color = Color.WHITE

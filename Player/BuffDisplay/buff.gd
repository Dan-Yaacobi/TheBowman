class_name BuffRect extends TextureRect

@onready var amount_label: Label = $Amount
@onready var panel: Panel = $Panel

@export var buff_ID: int = 0
@export var amount: int = 0

func set_buff(_texture: Texture, id: int, tooltip: String) -> void:
	set_tooltip(tooltip)
	amount_label = $Amount
	panel = $Panel
	buff_ID = id
	texture = _texture
	amount_label.text = str(1)
	amount = 1
	scale *= 0.5

func add_buff(_amount: int,buff_node: PlayerUpgrade, player: Player) -> void:
	set_tooltip(buff_node.get_buff_tooltip(player))
	amount += _amount
	panel.size = Vector2(3 + 3 * int(log(amount)/log(10)),5)
	amount_label.text = str(amount)
	

func set_tooltip(_text: String) -> void:
	tooltip_text = _text
	pass

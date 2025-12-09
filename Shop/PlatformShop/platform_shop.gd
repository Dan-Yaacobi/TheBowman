class_name PlatformShop extends Node2D

@onready var tiles: TilesControl = $Tiles
@onready var fall: Area2D = $Fall
@onready var reset_button: PlatformResetButton = $ResetButton
@onready var player_spawn: PlayerSpawn = $PlayerSpawn

var playground: PlayGround
var player: Player
#var buttons: Dictionary = {"Left": null, "Right": null}

var current_platform_button: TextureButton = null

func _ready() -> void:
		fall.body_entered.connect(to_menu)

func set_scene(_player: Player) -> void:
	if _player != null:
		player = _player
		player.global_position = player_spawn.global_position
		player.stats.in_menu = true
		player.set_camera(Rect2i(Vector2(-100000,-100000),Vector2(10000000,10000000)),16)
		visible = true
		tiles.collision_enabled = true
		set_shop_platforms()
		fall.monitoring = true
		fall.monitorable = true

			
		for child in get_children():
			#if child is BuyPlatform:
				#print(child)
				#child.set_buttons()
				#buttons[child.side] = child
				
			if child is PlatformButton:
				child.set_button(self,player)
				reset_button.refund_value = child.price
				
		for child in get_parent().get_children():
			if child is PlayGround:
				playground = child
		#set_prices()

func exit_scene(_player) -> void:
	visible = false
	tiles.collision_enabled = false
	fall.monitoring = false
	fall.monitorable = false

#func set_prices() -> void:
	#for key in buttons.keys():
		#buttons[key].price = pow(tiles.get_used_cells().size(),3)
		#buttons[key].update_price_label()
		#if not buttons[key].check_if_can_buy(player.stats.money):
			#buttons[key].button.modulate = Color.RED
		#else:
			#buttons[key].button.modulate = Color.WHITE

func set_shop_platforms() -> void:
	for child in get_parent().get_children():
		if child is PlayGround:
			for cell in child.tiles.get_used_cells():
				tiles.set_cell(cell,0,Vector2i(0,0))

func to_menu(b) -> void:
	if b is Player:
		EventBus.changed_scene.emit("Menu")

#func buy_platforms(side: String) -> void:
	#if player != null:
		#var price = buttons[side].check_if_can_buy(player.stats.money)
		#if price:
			#player.collect_money(-price)
			#set_current_money(player.stats.money)
			#
			#if side == "Left":
				#tiles.add_left_tile(0)
				#playground.tiles.add_left_tile(0)
				#
			#elif side == "Right":
				#tiles.add_right_tile(0)
				#playground.tiles.add_right_tile(0)
				#
			#set_prices()
			
func add_platform_at(coords: Vector2,color_index: int) -> void:
	tiles.add_tile_at(coords,color_index)
	playground.tiles.add_tile_at(coords,color_index)
	
func refund(amount: int) -> void:
	player.collect_money(amount)
	player.money_changed.emit(player.stats.money)

func reset_platforms() -> void:
	playground.tiles.reset_tiles()
	for child in get_children():
		if child is PlatformButton:
			child.reset()
			

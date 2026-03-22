extends Node2D

@onready var menu_buttons: VBoxContainer = $VBoxContainer
@onready var options: Panel = $Options
@onready var shop: Panel = $Shop
@onready var panels: Node2D = $Shop/Panels
@onready var buttons: Node2D = $Shop/Buttons
@onready var total_coins: Label = $coins
@onready var actual_shop: Panel = $"Actual shop"
@onready var upgrades: Panel = $Upgrades
@onready var coin_multi: HBoxContainer = $"Upgrades/coin multiplier/coin_multi"
@onready var coin_timer: HBoxContainer = $"Upgrades/coin timer/coin_timer"
@onready var weapon_amount: HBoxContainer = $"Upgrades/weapon amount/weapon_amount"

var coin_multi_list = []
var coin_timer_list = []
var weapon_amount_list = []

# The costs for levels 1 through 5
const UPGRADE_COSTS = [10, 30, 50, 100, 200]

func _ready() -> void:
	# --- Initial UI State ---
	menu_buttons.visible = true
	options.visible = false
	shop.visible = false
	buttons.visible = false
	actual_shop.visible = false
	upgrades.visible = false
	
	# --- Populate Lists ---
	coin_multi_list = coin_multi.get_children()
	coin_timer_list = coin_timer.get_children()
	weapon_amount_list = weapon_amount.get_children()

	# --- Setup Connections ---
	_setup_upgrade_buttons(coin_multi_list, "multi")
	_setup_upgrade_buttons(coin_timer_list, "timer")
	_setup_upgrade_buttons(weapon_amount_list, "weapon")
	
	# --- Initial UI Refresh ---
	_update_all_ui()

# --- UPGRADE SYSTEM LOGIC ---

func _setup_upgrade_buttons(button_list: Array, upgrade_type: String) -> void:
	for i in range(button_list.size()):
		var btn = button_list[i]
		# Connects every button to a single function using 'bind'
		btn.pressed.connect(_on_upgrade_purchased.bind(upgrade_type, i))

func _on_upgrade_purchased(upgrade_type: String, level_index: int) -> void:
	var cost = UPGRADE_COSTS[level_index]
	
	if Global.coins >= cost:
		Global.coins -= cost
		
		# Apply Stats and Track Levels
		if upgrade_type == "multi":
			Global.multi_level += 1
			Global.multi += 1
		elif upgrade_type == "timer":
			Global.timer_level += 1
			Global.timer -= 0.2
		elif upgrade_type == "weapon":
			Global.weapon_level += 1
			Global.weapon += 1
			
		_update_all_ui()

func _update_all_ui() -> void:
	total_coins.text = "Coins:" + str(Global.coins)
	
	_update_button_row(coin_multi_list, Global.multi_level)
	_update_button_row(coin_timer_list, Global.timer_level)
	_update_button_row(weapon_amount_list, Global.weapon_level)

func _update_button_row(button_list: Array, current_level: int) -> void:
	for i in range(button_list.size()):
		var btn = button_list[i]
		
		if i < current_level:
			# Purchased
			btn.disabled = true
			btn.text = "Max"
		elif i == current_level:
			# Next available
			var cost = UPGRADE_COSTS[i]
			btn.disabled = Global.coins < cost
			btn.text = str(cost)
		else:
			# Locked (must buy previous first)
			btn.disabled = true
			btn.text = "Lock"

# --- NAVIGATION LOGIC ---

func _on_close_options_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func _on_close_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func _on_options_pressed() -> void:
	menu_buttons.visible = false
	options.visible = true

func _on_shop_pressed() -> void:
	menu_buttons.visible = false
	actual_shop.visible = true
	buttons.visible = true

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_weapons_pressed() -> void:
	actual_shop.visible = false
	shop.visible = true

func _on_upgrades_pressed() -> void:
	actual_shop.visible = false
	upgrades.visible = true
	_update_all_ui() 

func _on_close_upgrades_pressed() -> void:
	# Return to start menu
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

extends Node2D
@onready var coin_spawner: Timer = $CoinSpawner

@export var coin_scene: PackedScene
@export var spawn_area_width := 700   
@export var spawn_height := -300 

@onready var buttons: Node2D = $Weapons

@onready var coin: Node2D = $"."
@onready var dustbin: Area2D = $dustbin 
@onready var entity: CharacterBody2D = $entity
@onready var detection_area: Area2D = $dustbin/DetectionArea 
@onready var bookmark: Area2D = $bookmark
@onready var button: Button = $Button
@onready var recyclebinpopup: AudioStreamPlayer2D = $recyclebinpopup
@onready var total_coins: Label = $"total coins"
var button_list=[]
var FIXED_TARGET_POS: Vector2     
var FIXED_HIDDEN_POS: Vector2    
var is_visible := false                

# --- Bookmark Settings ---
var BOOKMARK_TARGET_POS: Vector2
var BOOKMARK_HIDDEN_POS: Vector2

var entity_default_pos: Vector2

func _ready() -> void:
	coin_spawner.wait_time=Global.timer
	for i in buttons.get_children():
		button_list.append(i)
	for i in range(len(button_list)):
		if i not in Global.active_loadout:
			button_list[i].visible=false
			button_list[i].collision_mask=0
			button_list[i].collision_layer=0
		else:
			button_list[i].collision_mask=1
			button_list[i].collision_layer=1
	
	if Global.selected_visual_preset==1:
		bookmark.visible=false
	$CoinSpawner.timeout.connect(_spawn_coin)
	var coins_total=str(Global.coins)
	if int(coins_total)<=9:
		coins_total="00"+ coins_total
	if int(coins_total)<=99 and int(coins_total)>=10:
		coins_total="0"+coins_total
	total_coins.text = "Coins:" +coins_total
	if Global.coins>=999:
		Global.coins=0
	
	# 1. Capture Dustbin positions
	FIXED_TARGET_POS = dustbin.global_position
	FIXED_HIDDEN_POS = Vector2(-300, FIXED_TARGET_POS.y)
	
	# 2. Capture Bookmark positions
	BOOKMARK_TARGET_POS = bookmark.global_position
	BOOKMARK_HIDDEN_POS = BOOKMARK_TARGET_POS - Vector2(300, 0)
	
	# 3. Setup Detection Area
	detection_area.top_level = true
	detection_area.global_position = FIXED_TARGET_POS
	detection_area.scale = Vector2(1.5, 1.5) 
	
	entity_default_pos = entity.global_position
	
	# 4. Initialize states
	dustbin.global_position = FIXED_HIDDEN_POS
	dustbin.modulate.a = 0
	
	# 5. Conditionally Setup Dustbin Logic
	if Global.selected_visual_preset == 0:
		# Preset 0: Enable dustbin mechanics
		detection_area.body_entered.connect(_on_detection_entered)
		detection_area.body_exited.connect(_on_detection_exited)
		dustbin.body_entered.connect(_on_dustbin_body_entered)
	else:
		# Other Presets: Disable physics monitoring to save performance
		detection_area.monitoring = false
		dustbin.monitoring = false

func _spawn_coin():
	var coin_instance = coin_scene.instantiate()
	var x_pos = randf() * spawn_area_width - spawn_area_width / 2
	coin_instance.global_position = Vector2(x_pos, spawn_height)
	add_child(coin_instance)
	
func _on_detection_entered(body: Node2D):
	if body == entity:
		animate_dustbin(true)

func _on_detection_exited(body: Node2D):
	if body == entity:
		animate_dustbin(false)

func animate_dustbin(should_appear: bool):
	if is_visible == should_appear: return 
	is_visible = should_appear
	
	var tween = create_tween().set_parallel(true)
	
	var d_pos = FIXED_TARGET_POS if should_appear else FIXED_HIDDEN_POS
	var d_alpha = 1.0 if should_appear else 0.0
	
	var b_pos = BOOKMARK_HIDDEN_POS if should_appear else BOOKMARK_TARGET_POS
	var b_alpha = 0.0 if should_appear else 1.0
	
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	
	tween.tween_property(dustbin, "global_position", d_pos, 0.4)
	tween.tween_property(dustbin, "modulate:a", d_alpha, 0.4)
	
	tween.tween_property(bookmark, "global_position", b_pos, 0.4)
	tween.tween_property(bookmark, "modulate:a", b_alpha, 0.4)

func _on_dustbin_body_entered(body: Node2D) -> void:
	if body == entity:
		recyclebinpopup.play()
		reset_entity()

func reset_entity():
	if "is_dragging" in entity:
		entity.is_dragging = false
	entity.velocity = Vector2.ZERO
	entity.global_position = entity_default_pos
	
func addcoins():
	Global.coins += 1*Global.multi
	var coins_total=str(Global.coins)
	if int(coins_total)<=9:
		coins_total="00"+ coins_total
	if int(coins_total)<=99 and int(coins_total)>=10:
		coins_total="0"+coins_total
	total_coins.text = "Coins:" +coins_total

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

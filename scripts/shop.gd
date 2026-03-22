extends Panel
@onready var weapon_selected: AudioStreamPlayer2D = $"../weapon selected"
@onready var cant_select_more: AudioStreamPlayer2D = $"../cant select more"

@onready var panels: Node2D = $Panels
@onready var buttons: Node2D = $Buttons

var buttonsl: Array = []
var panelsl: Array = []

func _ready() -> void:
	panels.visible = true
	buttonsl = buttons.get_children()
	panelsl = panels.get_children()

	var n = min(buttonsl.size(), panelsl.size())

	for i in range(n):
		panelsl[i].visible = false
		buttonsl[i].pressed.connect(_on_button_clicked.bind(i))
	
	# NEW: Keep the colors green when returning from the main menu
	_refresh_button_colors()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("escape"):
		get_tree().change_scene_to_file("res://scenes/start_menu.tscn")
	update_panel_visibility()

func _on_button_clicked(index: int) -> void:
	if Global.active_loadout.has(index):
		Global.active_loadout.erase(index)
		buttonsl[index].modulate = Color.WHITE 
	else:
		if Global.active_loadout.size() < Global.weapon:
			Global.active_loadout.append(index)
			buttonsl[index].modulate = Color(0.5, 1, 0.5) # Green
			weapon_selected.play()
		else:
			# NEW: Red Flash Logic
			_flash_red(index)
			cant_select_more.play()

# NEW: Flash red and disappear instantly
func _flash_red(index: int):
	var btn = buttonsl[index]
	var tween = create_tween()
	btn.modulate = Color(1, 0, 0) # Set to pure Red
	# Wait 0.1 seconds then snap back to white
	tween.tween_interval(0.1)
	tween.tween_callback(func(): btn.modulate = Color.WHITE)

# NEW: Checks Global.active_loadout to re-apply green colors when menu opens
func _refresh_button_colors():
	for i in range(buttonsl.size()):
		if Global.active_loadout.has(i):
			buttonsl[i].modulate = Color(0.5, 1, 0.5) # Green
		else:
			buttonsl[i].modulate = Color.WHITE

func update_panel_visibility() -> void:
	var n = min(buttonsl.size(), panelsl.size())
	for i in range(n):
		var is_selected = Global.active_loadout.has(i)
		
		# Panel Visibility logic
		if is_selected or buttonsl[i].is_hovered():
			panelsl[i].visible = true
		else:
			panelsl[i].visible = false

		# Scaling logic (No Modulate here, so it doesn't fight the flash)
		if is_selected:
			buttonsl[i].scale = Vector2(2.3, 2.3)
		elif buttonsl[i].is_hovered():
			buttonsl[i].scale = Vector2(2.15, 2.15)
		else:
			buttonsl[i].scale = Vector2(2, 2)

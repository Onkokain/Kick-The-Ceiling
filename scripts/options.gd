extends Panel
@onready var bg_slider: HSlider = $Background
@onready var sfx_slider: HSlider = $"Sound Effects"
@onready var visual_options: OptionButton = $OptionButton


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# 1. LOAD values from Global when the menu opens
	bg_slider.value = Global.music_volume
	sfx_slider.value = Global.sfx_volume
	visual_options.selected = Global.selected_visual_preset
	
	# 2. CONNECT signals to detect changes
	bg_slider.value_changed.connect(_on_bg_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)
	visual_options.item_selected.connect(_on_visual_selected)

# 3. SAVE to Global whenever the user moves a slider or picks an option
func _on_bg_slider_changed(value: float) -> void:
	Global.music_volume = value
	# Optional: Actually change the volume here too
	# AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_sfx_slider_changed(value: float) -> void:
	Global.sfx_volume = value

func _on_visual_selected(index: int) -> void:
	Global.selected_visual_preset = index


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("escape"):
		get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

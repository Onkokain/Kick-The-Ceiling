extends Panel

func _process(delta: float) -> void:
	if Input.is_action_pressed("escape"):
		get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

func _on_close_settings_2_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/start_menu.tscn")

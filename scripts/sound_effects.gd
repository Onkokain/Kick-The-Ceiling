extends HSlider
@export var audio_bus_name: String
@onready var sound: AudioStreamPlayer2D = $"../../sound"



var audio_bus_id
func _ready():
	audio_bus_id=AudioServer.get_bus_index(audio_bus_name)
func _on_value_changed(value: float) -> void:
	sound.play()
	var db=linear_to_db(value)
	AudioServer.set_bus_volume_db(audio_bus_id,db)
 

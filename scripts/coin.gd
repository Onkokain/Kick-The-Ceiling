extends CharacterBody2D

@onready var game: Node2D = $"../.."
@onready var pickup_area: Area2D = $PickupArea
@onready var coin_pickup: AudioStreamPlayer2D = $"../AudioStreamPlayer2D"

var gravity := 500

func _ready():
	pickup_area.body_entered.connect(_on_pickup)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	
	move_and_slide()

func _on_pickup(body):
	if body is CharacterBody2D and body.name=='entity':
		coin_pickup.play()
		game.addcoins()
		queue_free()

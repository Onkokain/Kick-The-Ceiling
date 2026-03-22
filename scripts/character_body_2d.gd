extends CharacterBody2D

@onready var drop: AudioStreamPlayer2D = $drop
@onready var rwall: CollisionShape2D = $"../StaticBody2D/rwall"
@onready var lwall: CollisionShape2D = $"../StaticBody2D/lwall"
@onready var floor: CollisionShape2D = $"../StaticBody2D/floor"
@onready var ceiling: CollisionShape2D = $"../StaticBody2D/ceiling"
@onready var sprite: Sprite2D = $Sprite2D 
@onready var single_hit: AudioStreamPlayer2D = $"single hit"

@export var gravity = 900.0
@export var throw_multiplier = 0.5
@export var drag_smoothness = 0.25 

# --- Squish Settings ---
@export var impact_squish = 0.4
@export var recovery_speed = 10.0
@export var min_impact_velocity = 100.0

# --- Auto-Drop Settings ---
@export var max_drag_time = 2.0

var is_dragging = false
var drag_offset = Vector2.ZERO
var velocity_samples = [] 
const MAX_SAMPLES = 5
var original_scale = Vector2.ONE
var current_drag_time = 0.0

func _ready():
	original_scale = sprite.scale

func _physics_process(delta):
	if is_dragging:
		_handle_drag(delta)
	else:
		_handle_physics(delta)
		sprite.modulate = sprite.modulate.lerp(Color.WHITE, recovery_speed * delta)
	
	# --- SCALE LOGIC ---
	# Determine what size we WANT to be
	var target_scale = original_scale
	if is_dragging:
		target_scale = original_scale * 0.9 # Shrink slightly while held
	
	# Transition to that size (This handles the "growing back" after a tap)
	sprite.scale = sprite.scale.lerp(target_scale, recovery_speed * delta)

func _handle_drag(delta):
	current_drag_time += delta
	var time_percent = current_drag_time / max_drag_time
	sprite.modulate = Color(1.0, 1.0 - time_percent, 1.0 - time_percent)
	
	if current_drag_time >= max_drag_time:
		is_dragging = false
		current_drag_time = 0.0
		return 
	
	var target_position = get_global_mouse_position() - drag_offset
	var last_pos = global_position
	global_position = global_position.lerp(target_position, 1.0 - drag_smoothness)
	
	var current_velocity = (global_position - last_pos) / delta
	_update_velocity_buffer(current_velocity)
	velocity = _get_average_velocity()

func _handle_physics(delta):
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.x = move_toward(velocity.x, 0, 25) 
		
	var pre_move_velocity = velocity
	move_and_slide()

	var collision_count = get_slide_collision_count()
	
	# Check if we hit something with enough speed
	if collision_count > 0 and pre_move_velocity.length() > min_impact_velocity:
		# --- PLAY SOUND ---
		if not drop.playing: # Prevents the sound from "stacking" and getting too loud
			# Optional: Randomize pitch slightly so every hit sounds unique
			drop.pitch_scale = randf_range(0.8, 1.2) 
			drop.play()
		
		# --- SQUISH LOGIC ---
		var collision_index = collision_count - 1
		if collision_count > 1 and randf() > 0.5:
			collision_index = 0
		
		var collision = get_slide_collision(collision_index)
		var normal = collision.get_normal()
		
		if abs(normal.x) > 0.5: 
			sprite.scale.x = original_scale.x * (1.0 - impact_squish)
			sprite.scale.y = original_scale.y * (1.0 + impact_squish)
		elif abs(normal.y) > 0.5: 
			sprite.scale.x = original_scale.x * (1.0 + impact_squish)
			sprite.scale.y = original_scale.y * (1.0 - impact_squish)
func _update_velocity_buffer(new_vel):
	velocity_samples.push_back(new_vel)
	if velocity_samples.size() > MAX_SAMPLES:
		velocity_samples.pop_front()

func _get_average_velocity() -> Vector2:
	if velocity_samples.is_empty(): return Vector2.ZERO
	var sum = Vector2.ZERO
	for v in velocity_samples:
		sum += v
	return (sum / velocity_samples.size()) * throw_multiplier

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		# --- LEFT CLICK (Drag and Hit) ---
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = true
			current_drag_time = 0.0
			drag_offset = get_global_mouse_position() - global_position
			velocity_samples.clear() 
			
			# Trigger effects
			_trigger_hit_effects()

		# --- RIGHT CLICK (Just Hit) ---
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_trigger_hit_effects()

# Helper function to keep the code clean since both clicks do the same "hit" logic
func _trigger_hit_effects():
	# Play the hit sound with a random pitch for variety
	single_hit.pitch_scale = randf_range(0.9, 1.1)
	single_hit.play()
	
	# The "Pop" effect
	sprite.scale = original_scale * 0.7

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if not event.pressed and is_dragging:
			is_dragging = false
			current_drag_time = 0.0

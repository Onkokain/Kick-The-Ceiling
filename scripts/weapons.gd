extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D 

@export var drag_smoothness = 0.25 
@export var throw_multiplier = 0.5
@export var friction = 2.0 

@export var impact_squish = 0.4
@export var recovery_speed = 10.0
@export var min_impact_velocity = 100.0

var is_dragging = false
var is_right_toggle_active = false
var is_held = false 
var drag_offset = Vector2.ZERO
var velocity_samples = [] 
const MAX_SAMPLES = 5
var original_scale = Vector2.ONE

func _ready():
	original_scale = sprite.scale
	input_pickable = true # Make sure weapons can be clicked

func _physics_process(delta):
	if is_dragging or is_right_toggle_active:
		_handle_drag(delta)
	else:
		_handle_physics(delta)
	sprite.scale = sprite.scale.lerp(original_scale, recovery_speed * delta)

func _handle_drag(delta):
	var target_position = get_global_mouse_position() - drag_offset
	var last_pos = global_position
	global_position = global_position.lerp(target_position, 1.0 - drag_smoothness)
	
	var current_velocity = (global_position - last_pos) / delta
	_update_velocity_buffer(current_velocity)
	velocity = _get_average_velocity()

func _handle_physics(delta):
	velocity = velocity.lerp(Vector2.ZERO, friction * delta)
	move_and_slide()
	if get_slide_collision_count() > 0 and velocity.length() > min_impact_velocity:
		_apply_impact_squish()

func _apply_impact_squish():
	var collision = get_slide_collision(0)
	var normal = collision.get_normal()
	if abs(normal.x) > 0.5:
		sprite.scale = Vector2(original_scale.x * (1.0 - impact_squish), original_scale.y * (1.0 + impact_squish))
	else:
		sprite.scale = Vector2(original_scale.x * (1.0 + impact_squish), original_scale.y * (1.0 - impact_squish))

# --- Selection Logic ---

# --- Selection Logic ---

func _pick_up():
	is_held = true
	Global.current_selected_count += 1
	# REMOVE: input_pickable = false 
	# If you need to click through to others, use Z-index and 
	# check if the click was "handled" instead.
	z_index = 10 
	drag_offset = get_global_mouse_position() - global_position
	velocity_samples.clear()

func _drop():
	if is_held:
		is_held = false
		Global.current_selected_count -= 1
		z_index = 0
		is_dragging = false
		is_right_toggle_active = false
		# Calculate final throw velocity
		velocity = _get_average_velocity()

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed:
		# RIGHT CLICK TOGGLE ON
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if not is_held and Global.current_selected_count < Global.weapon:
				is_right_toggle_active = true
				_pick_up()
			elif is_right_toggle_active: # If already held by right-click, drop it
				_drop()
				
		# LEFT CLICK DRAG
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if not is_held and Global.current_selected_count < Global.weapon:
				is_dragging = true
				_pick_up()

func _input(event):
	if event is InputEventMouseButton:
		# Only handle GLOBAL release for the left-click drag 
		# Right-click is handled specifically in _input_event for the toggle
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			if is_dragging:
				_drop()
# --- Helpers ---
func _update_velocity_buffer(new_vel):
	velocity_samples.push_back(new_vel)
	if velocity_samples.size() > MAX_SAMPLES: velocity_samples.pop_front()

func _get_average_velocity() -> Vector2:
	if velocity_samples.is_empty(): return Vector2.ZERO
	var sum = Vector2.ZERO
	for v in velocity_samples: sum += v
	return (sum / velocity_samples.size()) * throw_multiplier

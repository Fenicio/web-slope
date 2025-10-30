extends Node3D

@export var slope_width = 30.0

# Skiing mechanics constants
const TILT_SPEED = 0.03
const MAX_TILT = 0.5
const SLIDE_ACCELERATION = 0.015
const LATERAL_DAMPING = 0.98

# Skiing state
var player_x = 0.0
var player_tilt = 0.0
var lateral_velocity = 0.0
var tilt_direction = 0  # -1 = left, 0 = none, 1 = right
var last_tilt_direction = 0

var game_manager: Node
var timing_boost: Node

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	# Get timing boost UI (will be available after UI is set up)
	await get_tree().process_frame
	timing_boost = get_node_or_null("/root/Main/UI/TimingBoost")

func _process(delta):
	if not game_manager.is_playing or game_manager.game_over or game_manager.won or game_manager.is_paused:
		return

	# Determine desired tilt direction based on input
	var desired_tilt_direction = 0
	if Input.is_action_pressed("move_left"):
		desired_tilt_direction = -1
	if Input.is_action_pressed("move_right"):
		desired_tilt_direction = 1

	# Detect direction change for speed boost (notify game manager)
	if desired_tilt_direction != 0 and desired_tilt_direction != last_tilt_direction and last_tilt_direction != 0:
		# Check timing and trigger boost based on timing accuracy
		var is_perfect = false
		if timing_boost:
			is_perfect = await timing_boost.check_timing()
		game_manager.trigger_speed_boost(is_perfect)

	# Update tilt direction tracking
	if desired_tilt_direction != 0:
		tilt_direction = desired_tilt_direction
		last_tilt_direction = desired_tilt_direction

	# Gradually tilt towards desired direction
	var target_tilt = desired_tilt_direction * MAX_TILT
	if abs(player_tilt - target_tilt) > 0.01:
		player_tilt += (target_tilt - player_tilt) * TILT_SPEED * 3
	else:
		player_tilt = target_tilt

	# Apply tilt to player mesh (rotate on Z axis for side tilt)
	rotation.z = -player_tilt

	# Apply turning rotation to player mesh (rotate on Y axis to face movement direction)
	# Rotate based on lateral velocity for smooth turning
	rotation.y = lateral_velocity * -2.0  # Multiplier controls turn angle

	# Build up lateral velocity based on tilt
	if player_tilt != 0:
		lateral_velocity += player_tilt * SLIDE_ACCELERATION

	# Apply damping to lateral velocity
	lateral_velocity *= LATERAL_DAMPING

	# Move player based on lateral velocity
	player_x += lateral_velocity

	# Constrain player to slope
	var max_x = slope_width / 2.0 - 2.0
	player_x = clamp(player_x, -max_x, max_x)

	# Update position
	position.x = player_x

func get_player_x():
	return player_x

func reset_position():
	player_x = 0.0
	player_tilt = 0.0
	lateral_velocity = 0.0
	tilt_direction = 0
	last_tilt_direction = 0
	position = Vector3(0, 1, 0)
	rotation.z = 0
	rotation.y = 0

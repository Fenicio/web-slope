extends Node

# Game State
var is_playing = false
var is_paused = false
var lives = 3
var gems_collected = 0
var gems_needed = 3
var speed = 70.0
var base_speed = 70.0
var max_speed = 200.0
var distance = 0.0
var game_over = false
var won = false

# Skiing mechanics state
var speed_boost_time = 0.0
var danger_level = 30.0
var danger_speed = 0.03
var game_over_reason = "You crashed into too many obstacles!"

# Game Constants
const SLOPE_WIDTH = 30.0
const SLOPE_SEGMENT_LENGTH = 50.0
const PLAYER_SPEED = 0.3
const COLLISION_RADIUS = 1.5
const GEM_COLLISION_RADIUS = 2.0

# Skiing mechanics constants
const SPEED_BOOST_DURATION = 0.5  # seconds
const SPEED_BOOST_AMOUNT = 30.0
const SPEED_DECAY_RATE = 0.02

# Signals
signal lives_changed(new_lives)
signal gems_changed(collected, needed)
signal speed_changed(new_speed, boosting)
signal distance_changed(new_distance)
signal danger_changed(new_danger)
signal game_started
signal game_paused
signal game_resumed
signal game_over_signal(reason)
signal game_won
signal exit_activated

func _ready():
	reset_game()

func reset_game():
	is_playing = false
	is_paused = false
	lives = 3
	gems_collected = 0
	speed = base_speed
	distance = 0.0
	game_over = false
	won = false
	speed_boost_time = 0.0
	danger_level = 30.0
	danger_speed = 0.03
	game_over_reason = "You crashed into too many obstacles!"
	emit_signal("lives_changed", lives)
	emit_signal("gems_changed", gems_collected, gems_needed)
	emit_signal("speed_changed", speed, false)
	emit_signal("distance_changed", distance)
	emit_signal("danger_changed", danger_level)

func start_game():
	is_playing = true
	is_paused = false
	emit_signal("game_started")

func toggle_pause():
	if game_over or won:
		return

	is_paused = !is_paused
	if is_paused:
		emit_signal("game_paused")
	else:
		emit_signal("game_resumed")

func collect_gem():
	gems_collected += 1
	emit_signal("gems_changed", gems_collected, gems_needed)

	if gems_collected >= gems_needed:
		emit_signal("exit_activated")

func trigger_speed_boost():
	speed_boost_time = SPEED_BOOST_DURATION
	speed = min(speed + SPEED_BOOST_AMOUNT, max_speed)
	emit_signal("speed_changed", speed, true)

func lose_life():
	lives -= 1
	emit_signal("lives_changed", lives)

	if lives <= 0:
		game_over_reason = "You crashed into too many obstacles!"
		trigger_game_over()

func trigger_game_over():
	game_over = true
	is_playing = false
	emit_signal("game_over_signal", game_over_reason)

func trigger_danger_overload():
	game_over_reason = "You were too slow! The danger caught up!"
	trigger_game_over()

func trigger_win():
	won = true
	is_playing = false
	emit_signal("game_won")

func update_distance(delta):
	if is_playing and !game_over and !won and !is_paused:
		distance += speed * delta
		emit_signal("distance_changed", distance)

		# Handle speed boost countdown
		if speed_boost_time > 0:
			speed_boost_time -= delta
			emit_signal("speed_changed", speed, true)
		else:
			# Gradually decrease speed towards base speed (when not boosting)
			if speed > base_speed:
				speed -= SPEED_DECAY_RATE
				speed = max(speed, base_speed)
			emit_signal("speed_changed", speed, false)

		# Increase danger level over time (speeds up as game progresses)
		danger_level += danger_speed
		danger_speed += 0.00001  # Gradually increase danger speed
		emit_signal("danger_changed", danger_level)

		# Check if danger bar caught up to player speed - GAME OVER
		if danger_level >= speed:
			trigger_danger_overload()

func get_scroll_speed():
	if is_playing and !game_over and !won and !is_paused:
		return speed * 0.016
	return 0.0

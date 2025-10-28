extends Node

# Game State
var is_playing = false
var is_paused = false
var lives = 3
var gems_collected = 0
var gems_needed = 3
var speed = 50.0
var base_speed = 50.0
var max_speed = 120.0
var distance = 0.0
var game_over = false
var won = false

# Game Constants
const SLOPE_WIDTH = 30.0
const SLOPE_SEGMENT_LENGTH = 50.0
const PLAYER_SPEED = 0.3
const COLLISION_RADIUS = 1.5
const GEM_COLLISION_RADIUS = 2.0

# Signals
signal lives_changed(new_lives)
signal gems_changed(collected, needed)
signal speed_changed(new_speed)
signal distance_changed(new_distance)
signal game_started
signal game_paused
signal game_resumed
signal game_over_signal
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
	emit_signal("lives_changed", lives)
	emit_signal("gems_changed", gems_collected, gems_needed)
	emit_signal("speed_changed", speed)
	emit_signal("distance_changed", distance)

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

func lose_life():
	lives -= 1
	emit_signal("lives_changed", lives)

	if lives <= 0:
		trigger_game_over()

func trigger_game_over():
	game_over = true
	is_playing = false
	emit_signal("game_over_signal")

func trigger_win():
	won = true
	is_playing = false
	emit_signal("game_won")

func update_distance(delta):
	if is_playing and !game_over and !won and !is_paused:
		distance += speed * delta
		speed = min(base_speed + distance * 0.01, max_speed)
		emit_signal("distance_changed", distance)
		emit_signal("speed_changed", speed)

func get_scroll_speed():
	if is_playing and !game_over and !won and !is_paused:
		return speed * 0.016
	return 0.0

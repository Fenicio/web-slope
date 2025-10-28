extends Node3D

@export var player_speed = 0.3
@export var slope_width = 30.0

var player_x = 0.0
var game_manager: Node

func _ready():
	game_manager = get_node("/root/Main/GameManager")

func _process(delta):
	if not game_manager.is_playing or game_manager.game_over or game_manager.won or game_manager.is_paused:
		return

	# Handle input
	if Input.is_action_pressed("move_left"):
		player_x -= player_speed
	if Input.is_action_pressed("move_right"):
		player_x += player_speed

	# Constrain player to slope
	var max_x = slope_width / 2.0 - 2.0
	player_x = clamp(player_x, -max_x, max_x)

	# Update position
	position.x = player_x

func get_player_x():
	return player_x

func reset_position():
	player_x = 0.0
	position = Vector3(0, 1, 0)

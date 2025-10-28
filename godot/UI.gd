extends CanvasLayer

# HUD elements
@onready var lives_label = $HUD/Stats/LivesLabel
@onready var gems_label = $HUD/Stats/GemsLabel
@onready var speed_label = $HUD/Stats/SpeedLabel
@onready var distance_label = $HUD/Stats/DistanceLabel
@onready var notification_label = $HUD/Notification

# Screens
@onready var start_screen = $StartScreen
@onready var pause_screen = $PauseScreen
@onready var gameover_screen = $GameOverScreen
@onready var win_screen = $WinScreen

# Pause screen stats
@onready var pause_distance_label = $PauseScreen/Panel/VBox/Stats/DistanceValue
@onready var pause_gems_label = $PauseScreen/Panel/VBox/Stats/GemsValue
@onready var pause_lives_label = $PauseScreen/Panel/VBox/Stats/LivesValue

# Game over screen stats
@onready var gameover_distance_label = $GameOverScreen/Panel/VBox/Stats/DistanceValue
@onready var gameover_gems_label = $GameOverScreen/Panel/VBox/Stats/GemsValue

# Win screen stats
@onready var win_distance_label = $WinScreen/Panel/VBox/Stats/DistanceValue

var game_manager: Node

func _ready():
	game_manager = get_node("/root/Main/GameManager")

	# Connect signals
	game_manager.lives_changed.connect(_on_lives_changed)
	game_manager.gems_changed.connect(_on_gems_changed)
	game_manager.speed_changed.connect(_on_speed_changed)
	game_manager.distance_changed.connect(_on_distance_changed)
	game_manager.game_started.connect(_on_game_started)
	game_manager.game_paused.connect(_on_game_paused)
	game_manager.game_resumed.connect(_on_game_resumed)
	game_manager.game_over_signal.connect(_on_game_over)
	game_manager.game_won.connect(_on_game_won)
	game_manager.exit_activated.connect(_on_exit_activated)

	# Initialize UI
	_update_all_stats()
	show_start_screen()

func _update_all_stats():
	_on_lives_changed(game_manager.lives)
	_on_gems_changed(game_manager.gems_collected, game_manager.gems_needed)
	_on_speed_changed(game_manager.speed)
	_on_distance_changed(game_manager.distance)

func _on_lives_changed(new_lives):
	lives_label.text = "Lives: %d" % new_lives

func _on_gems_changed(collected, needed):
	gems_label.text = "Gems: %d/%d" % [collected, needed]

func _on_speed_changed(new_speed):
	speed_label.text = "Speed: %d km/h" % int(new_speed)

func _on_distance_changed(new_distance):
	distance_label.text = "Distance: %d m" % int(new_distance)

func _on_game_started():
	start_screen.hide()
	pause_screen.hide()

func _on_game_paused():
	pause_distance_label.text = "%d m" % int(game_manager.distance)
	pause_gems_label.text = "%d/3" % game_manager.gems_collected
	pause_lives_label.text = "%d" % game_manager.lives
	pause_screen.show()

func _on_game_resumed():
	pause_screen.hide()

func _on_game_over():
	gameover_distance_label.text = "%d m" % int(game_manager.distance)
	gameover_gems_label.text = "%d/3" % game_manager.gems_collected
	gameover_screen.show()

func _on_game_won():
	win_distance_label.text = "%d m" % int(game_manager.distance)
	win_screen.show()

func _on_exit_activated():
	show_notification("All gems collected! Find the exit portal!")

func show_start_screen():
	start_screen.show()
	pause_screen.hide()
	gameover_screen.hide()
	win_screen.hide()

func show_notification(text: String):
	notification_label.text = text
	notification_label.show()

	# Hide after 3 seconds
	await get_tree().create_timer(3.0).timeout
	notification_label.hide()

func _on_start_button_pressed():
	game_manager.start_game()

func _on_restart_button_pressed():
	get_tree().reload_current_scene()

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		game_manager.toggle_pause()

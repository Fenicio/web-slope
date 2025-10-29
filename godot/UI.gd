extends CanvasLayer

# HUD elements
@onready var gems_label = $HUD/Stats/GemsLabel
@onready var speed_label = $HUD/Stats/SpeedLabel
@onready var distance_label = $HUD/Stats/DistanceLabel
@onready var notification_label = $HUD/Notification

# Speed bars
@onready var speed_bar_fill = $HUD/SpeedBar/Fill
@onready var danger_bar_fill = $HUD/DangerBar/Fill

# Screens
@onready var start_screen = $StartScreen
@onready var pause_screen = $PauseScreen
@onready var gameover_screen = $GameOverScreen
@onready var win_screen = $WinScreen

# Pause screen stats
@onready var pause_distance_label = $PauseScreen/Panel/VBox/Stats/DistanceValue
@onready var pause_gems_label = $PauseScreen/Panel/VBox/Stats/GemsValue

# Game over screen stats
@onready var gameover_distance_label = $GameOverScreen/Panel/VBox/Stats/DistanceValue
@onready var gameover_gems_label = $GameOverScreen/Panel/VBox/Stats/GemsValue
@onready var gameover_reason_label = $GameOverScreen/Panel/VBox/Reason

# Win screen stats
@onready var win_distance_label = $WinScreen/Panel/VBox/Stats/DistanceValue

var game_manager: Node

func _ready():
	game_manager = get_node("/root/Main/GameManager")

	# Connect signals
	game_manager.gems_changed.connect(_on_gems_changed)
	game_manager.speed_changed.connect(_on_speed_changed)
	game_manager.distance_changed.connect(_on_distance_changed)
	game_manager.danger_changed.connect(_on_danger_changed)
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
	_on_gems_changed(game_manager.gems_collected, game_manager.gems_needed)
	_on_speed_changed(game_manager.speed)
	_on_distance_changed(game_manager.distance)

func _on_gems_changed(collected, needed):
	gems_label.text = "Gems: %d/%d" % [collected, needed]

func _on_speed_changed(new_speed, boosting):
	speed_label.text = "Speed: %d km/h" % int(new_speed)

	# Update speed bar
	if speed_bar_fill:
		var speed_percent = (new_speed / game_manager.max_speed) * 100.0
		speed_bar_fill.size.y = speed_percent / 100.0 * 300.0  # 300 is the bar height
		speed_bar_fill.position.y = 300.0 - speed_bar_fill.size.y

		# Change color based on state
		if game_manager.danger_level >= new_speed * 0.9:
			speed_bar_fill.color = Color(1, 0, 0)  # Red when danger is close
		elif boosting:
			speed_bar_fill.color = Color(0, 1, 1)  # Cyan when boosting
		else:
			speed_bar_fill.color = Color(0, 0.5, 1)  # Blue normally

func _on_distance_changed(new_distance):
	distance_label.text = "Distance: %d m" % int(new_distance)

func _on_danger_changed(new_danger):
	# Update danger bar
	if danger_bar_fill:
		var danger_percent = (new_danger / game_manager.max_speed) * 100.0
		danger_bar_fill.size.y = danger_percent / 100.0 * 300.0
		danger_bar_fill.position.y = 300.0 - danger_bar_fill.size.y

func _on_game_started():
	start_screen.hide()
	pause_screen.hide()

func _on_game_paused():
	pause_distance_label.text = "%d m" % int(game_manager.distance)
	pause_gems_label.text = "%d/3" % game_manager.gems_collected
	pause_screen.show()

func _on_game_resumed():
	pause_screen.hide()

func _on_game_over(reason):
	gameover_distance_label.text = "%d m" % int(game_manager.distance)
	gameover_gems_label.text = "%d/3" % game_manager.gems_collected
	if gameover_reason_label:
		gameover_reason_label.text = reason
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

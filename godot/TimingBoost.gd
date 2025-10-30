extends Control

# Timing boost zones
const PERFECT_ZONE_START = 0.4  # 40% across the bar
const PERFECT_ZONE_END = 0.6    # 60% across the bar
const LINE_SPEED = 1.5           # Speed of the line animation

# UI elements (created programmatically)
var background_bar: ColorRect
var perfect_zone: ColorRect
var timing_line: ColorRect
var feedback_label: Label

# State
var line_position = 0.0  # 0.0 to 1.0
var line_direction = 1   # 1 = moving right, -1 = moving left
var game_manager: Node
var bar_width = 300.0
var bar_height = 40.0

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	setup_ui()

func setup_ui():
	# Position the timing boost UI
	position = Vector2(20, 150)
	size = Vector2(bar_width + 20, bar_height + 60)

	# Background bar (gray)
	background_bar = ColorRect.new()
	background_bar.size = Vector2(bar_width, bar_height)
	background_bar.position = Vector2(10, 10)
	background_bar.color = Color(0.2, 0.2, 0.2, 0.8)
	add_child(background_bar)

	# Perfect zone (yellow in the middle)
	perfect_zone = ColorRect.new()
	var zone_width = bar_width * (PERFECT_ZONE_END - PERFECT_ZONE_START)
	perfect_zone.size = Vector2(zone_width, bar_height)
	perfect_zone.position = Vector2(10 + bar_width * PERFECT_ZONE_START, 10)
	perfect_zone.color = Color(1, 1, 0, 0.6)  # Yellow with transparency
	add_child(perfect_zone)

	# Timing line (white/cyan)
	timing_line = ColorRect.new()
	timing_line.size = Vector2(4, bar_height)
	timing_line.position = Vector2(10, 10)
	timing_line.color = Color(0, 1, 1)  # Cyan
	add_child(timing_line)

	# Feedback label
	feedback_label = Label.new()
	feedback_label.position = Vector2(10, bar_height + 15)
	feedback_label.size = Vector2(bar_width, 30)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.add_theme_font_size_override("font_size", 20)
	feedback_label.text = ""
	add_child(feedback_label)

func _process(delta):
	if not game_manager.is_playing or game_manager.game_over or game_manager.won or game_manager.is_paused:
		return

	# Animate the line back and forth
	line_position += LINE_SPEED * line_direction * delta

	# Bounce at edges
	if line_position >= 1.0:
		line_position = 1.0
		line_direction = -1
		timing_line.color = Color(0, 1, 1)  # Reset color
	elif line_position <= 0.0:
		line_position = 0.0
		line_direction = 1
		timing_line.color = Color(0, 1, 1)  # Reset color

	# Update line visual position
	timing_line.position.x = 10 + line_position * bar_width

	# Highlight line if in perfect zone
	if is_in_perfect_zone():
		timing_line.color = Color(1, 1, 0)  # Yellow when in perfect zone
	else:
		timing_line.color = Color(0, 1, 1)  # Cyan otherwise

func is_in_perfect_zone() -> bool:
	return line_position >= PERFECT_ZONE_START and line_position <= PERFECT_ZONE_END

func check_timing() -> bool:
	"""Check if the timing is perfect. Returns true if in perfect zone."""
	var is_perfect = is_in_perfect_zone()

	# Visual feedback
	if is_perfect:
		show_feedback("PERFECT!", Color(1, 1, 0))
		# Flash effect
		timing_line.color = Color(1, 1, 1)
		perfect_zone.color = Color(1, 1, 0, 1.0)
		await get_tree().create_timer(0.1).timeout
		perfect_zone.color = Color(1, 1, 0, 0.6)
	else:
		show_feedback("OK", Color(0.7, 0.7, 0.7))

	return is_perfect

func show_feedback(text: String, color: Color):
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)

	# Fade out feedback after a short delay
	await get_tree().create_timer(0.3).timeout
	feedback_label.text = ""

func reset():
	line_position = 0.0
	line_direction = 1
	feedback_label.text = ""
	if timing_line:
		timing_line.color = Color(0, 1, 1)
	if perfect_zone:
		perfect_zone.color = Color(1, 1, 0, 0.6)

func reset_for_direction(direction: int):
	"""Reset the timing bar based on the player's turn direction.
	Direction: -1 for left, 1 for right"""
	if direction < 0:
		# Turning left - start from left edge, move right
		line_position = 0.0
		line_direction = 1
	else:
		# Turning right - start from right edge, move left
		line_position = 1.0
		line_direction = -1

	feedback_label.text = ""
	if timing_line:
		timing_line.color = Color(0, 1, 1)
		timing_line.position.x = 10 + line_position * bar_width
	if perfect_zone:
		perfect_zone.color = Color(1, 1, 0, 0.6)

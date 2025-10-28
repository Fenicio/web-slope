extends Node3D

var is_active = false
var z_position = -600.0
var game_manager: Node
var player: Node3D
var portal_mesh: MeshInstance3D

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	player = get_node("/root/Main/Player")

	# Create exit portal
	portal_mesh = MeshInstance3D.new()
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = 2.5
	torus_mesh.outer_radius = 3.0
	portal_mesh.mesh = torus_mesh

	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 1, 0)
	material.emission_enabled = true
	material.emission = Color(0, 1, 0)
	material.emission_energy_multiplier = 0.8
	portal_mesh.material_override = material

	portal_mesh.rotation_degrees = Vector3(90, 0, 0)
	position = Vector3(0, 3, z_position)

	add_child(portal_mesh)
	visible = false

	# Connect to exit_activated signal
	game_manager.exit_activated.connect(_on_exit_activated)

func _on_exit_activated():
	is_active = true
	visible = true
	print("Exit portal activated!")

func _process(delta):
	var scroll_speed = game_manager.get_scroll_speed()

	# Move exit
	position.z += scroll_speed
	z_position = position.z

	# Rotate exit
	portal_mesh.rotation.z += 0.02

	# Check collision with player
	if is_active:
		check_collision()

func check_collision():
	if not game_manager.is_playing or game_manager.game_over or game_manager.won or game_manager.is_paused:
		return

	var player_x = player.get_player_x()
	var player_z = player.position.z

	var dz = z_position - player_z
	if abs(dz) < 5 and abs(player_x) < 5:
		game_manager.trigger_win()

extends Node3D

const SLOPE_WIDTH = 30.0

var obstacles = []
var game_manager: Node
var player: Node3D

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	player = get_node("/root/Main/Player")
	generate_initial_obstacles()

func generate_initial_obstacles():
	for z in range(-50, -500, -10):
		if randf() < 0.3:
			create_obstacle(z)

func create_obstacle(z_position: float):
	var obstacle_type = "tree" if randf() < 0.6 else "mound"

	var obstacle_node = Node3D.new()

	if obstacle_type == "tree":
		# Trunk
		var trunk = MeshInstance3D.new()
		var trunk_mesh = CylinderMesh.new()
		trunk_mesh.top_radius = 0.3
		trunk_mesh.bottom_radius = 0.4
		trunk_mesh.height = 3.0
		trunk.mesh = trunk_mesh

		var trunk_material = StandardMaterial3D.new()
		trunk_material.albedo_color = Color(0.29, 0.145, 0.067)
		trunk.material_override = trunk_material
		trunk.position.y = 1.5

		obstacle_node.add_child(trunk)

		# Foliage
		var foliage = MeshInstance3D.new()
		var foliage_mesh = CylinderMesh.new()
		foliage_mesh.top_radius = 0.0
		foliage_mesh.bottom_radius = 2.0
		foliage_mesh.height = 4.0
		foliage.mesh = foliage_mesh

		var foliage_material = StandardMaterial3D.new()
		foliage_material.albedo_color = Color(0.051, 0.369, 0.051)
		foliage.material_override = foliage_material
		foliage.position.y = 4.0

		obstacle_node.add_child(foliage)
	else:
		# Mound
		var mound = MeshInstance3D.new()
		var mound_mesh = SphereMesh.new()
		mound_mesh.radius = 2.0
		mound_mesh.height = 4.0
		mound.mesh = mound_mesh

		var mound_material = StandardMaterial3D.new()
		mound_material.albedo_color = Color(0.8, 0.8, 0.8)
		mound.material_override = mound_material
		mound.scale.y = 0.5
		mound.position.y = 0.5

		obstacle_node.add_child(mound)

	# Position obstacle
	var x_position = (randf() - 0.5) * (SLOPE_WIDTH - 4)
	obstacle_node.position = Vector3(x_position, 0, z_position)

	add_child(obstacle_node)
	obstacles.append({
		"node": obstacle_node,
		"type": obstacle_type,
		"x": x_position,
		"z": z_position
	})

func _process(delta):
	var scroll_speed = game_manager.get_scroll_speed()

	# Move obstacles
	for i in range(obstacles.size() - 1, -1, -1):
		var obs = obstacles[i]
		obs.node.position.z += scroll_speed
		obs.z = obs.node.position.z

		# Remove obstacles that are too far behind
		if obs.z > 20:
			obs.node.queue_free()
			obstacles.remove_at(i)

			# Add new obstacle ahead
			var new_z = -450 + randf() * 50
			create_obstacle(new_z)

	# Check collisions
	check_collisions()

func check_collisions():
	if not game_manager.is_playing or game_manager.game_over or game_manager.won or game_manager.is_paused:
		return

	var player_x = player.get_player_x()
	var player_z = player.position.z

	for obs in obstacles:
		var dx = obs.x - player_x
		var dz = obs.z - player_z
		var distance = sqrt(dx * dx + dz * dz)

		if distance < game_manager.COLLISION_RADIUS:
			handle_collision()
			break

func handle_collision():
	if game_manager.game_over:
		return

	# Reduce speed instead of losing life
	var speed_reduction = 15.0  # Amount to reduce speed by
	game_manager.reduce_speed(speed_reduction)

	# Visual feedback
	print("Collision! Speed reduced by ", speed_reduction)

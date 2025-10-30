extends Node3D

const SLOPE_WIDTH = 30.0
const MONSTER_COLLISION_RADIUS = 2.5
const MONSTER_SPAWN_DISTANCE = 80.0  # Distance between monsters
const MONSTER_SPAWN_AHEAD = 500.0  # How far ahead to spawn monsters
const MONSTER_CLEANUP_DISTANCE = 50.0  # Remove monsters this far behind player

var monsters = []
var game_manager: Node
var player: Node3D
var furthest_monster_z = -100.0  # Track the furthest monster spawned

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	player = get_node("/root/Main/Player")
	generate_initial_monsters()

func generate_initial_monsters():
	# Spawn monsters more sparsely than obstacles
	for z in range(-100, -500, -80):
		if randf() < 0.4:  # 40% chance to spawn
			create_monster(z)
			furthest_monster_z = min(furthest_monster_z, z)

func create_monster(z_position: float):
	var monster_node = Node3D.new()

	# Create a menacing block placeholder
	var body = MeshInstance3D.new()
	var body_mesh = BoxMesh.new()
	body_mesh.size = Vector3(2.5, 3.0, 2.0)
	body.mesh = body_mesh

	var body_material = StandardMaterial3D.new()
	body_material.albedo_color = Color(0.1, 0.0, 0.1)  # Dark purple/black
	body_material.emission_enabled = true
	body_material.emission = Color(0.5, 0.0, 0.3)  # Purple glow
	body_material.emission_energy = 1.5
	body.material_override = body_material
	body.position.y = 1.5

	monster_node.add_child(body)

	# Add "eyes" for visual interest
	var eye1 = MeshInstance3D.new()
	var eye1_mesh = SphereMesh.new()
	eye1_mesh.radius = 0.2
	eye1.mesh = eye1_mesh

	var eye_material = StandardMaterial3D.new()
	eye_material.albedo_color = Color(1, 0, 0)  # Red eyes
	eye_material.emission_enabled = true
	eye_material.emission = Color(1, 0, 0)
	eye_material.emission_energy = 3.0
	eye1.material_override = eye_material
	eye1.position = Vector3(-0.5, 2.0, 0.8)

	monster_node.add_child(eye1)

	var eye2 = MeshInstance3D.new()
	eye2.mesh = eye1_mesh
	eye2.material_override = eye_material
	eye2.position = Vector3(0.5, 2.0, 0.8)

	monster_node.add_child(eye2)

	# Position monster
	var x_position = (randf() - 0.5) * (SLOPE_WIDTH - 4)
	monster_node.position = Vector3(x_position, 0, z_position)

	add_child(monster_node)
	monsters.append({
		"node": monster_node,
		"x": x_position,
		"z": z_position
	})

func _process(delta):
	var scroll_speed = game_manager.get_scroll_speed()
	var player_z = player.position.z

	# Spawn new monsters ahead of the player
	while furthest_monster_z > player_z - MONSTER_SPAWN_AHEAD:
		furthest_monster_z -= MONSTER_SPAWN_DISTANCE
		if randf() < 0.4:  # 40% chance to spawn
			create_monster(furthest_monster_z)

	# Move monsters
	for i in range(monsters.size() - 1, -1, -1):
		var monster = monsters[i]
		monster.node.position.z += scroll_speed
		monster.z = monster.node.position.z

		# Add slight bobbing animation
		monster.node.position.y = sin(Time.get_ticks_msec() * 0.002 + i) * 0.3

		# Rotate for menacing effect
		monster.node.rotation.y += delta * 2.0

		# Remove monsters that are too far behind
		if monster.z > player_z + MONSTER_CLEANUP_DISTANCE:
			monster.node.queue_free()
			monsters.remove_at(i)

	# Check collisions
	check_collisions()

func check_collisions():
	if not game_manager.is_playing or game_manager.game_over or game_manager.won or game_manager.is_paused:
		return

	var player_x = player.get_player_x()
	var player_z = player.position.z

	for monster in monsters:
		var dx = monster.x - player_x
		var dz = monster.z - player_z
		var distance = sqrt(dx * dx + dz * dz)

		if distance < MONSTER_COLLISION_RADIUS:
			handle_monster_grab()
			break

func handle_monster_grab():
	if game_manager.game_over:
		return

	# Instant game over when grabbed by monster
	game_manager.grabbed_by_monster()
	print("Grabbed by monster! Game Over!")

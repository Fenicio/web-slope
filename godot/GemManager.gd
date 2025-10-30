extends Node3D

const SLOPE_WIDTH = 30.0
const GEM_SPAWN_DISTANCE = 150.0  # Distance between gems
const GEM_SPAWN_AHEAD = 500.0  # How far ahead to spawn gems
const GEM_CLEANUP_DISTANCE = 50.0  # Remove gems this far behind player

var gems = []
var game_manager: Node
var player: Node3D
var furthest_gem_z = -100.0  # Track the furthest gem spawned

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	player = get_node("/root/Main/Player")
	generate_initial_gems()

func reset():
	# Clear all existing gems
	for gem in gems:
		if is_instance_valid(gem.node):
			gem.node.queue_free()
	gems.clear()
	furthest_gem_z = -100.0
	generate_initial_gems()

func generate_initial_gems():
	for i in range(game_manager.gems_needed):
		var z_pos = -100 - i * GEM_SPAWN_DISTANCE
		create_gem(z_pos)
		furthest_gem_z = min(furthest_gem_z, z_pos)

func create_gem(z_position: float):
	var gem_node = Node3D.new()

	# Gem mesh
	var gem_mesh_instance = MeshInstance3D.new()
	var gem_mesh = BoxMesh.new()
	gem_mesh.size = Vector3(1, 1, 1)
	gem_mesh_instance.mesh = gem_mesh

	var gem_material = StandardMaterial3D.new()
	gem_material.albedo_color = Color(0, 1, 1)
	gem_material.emission_enabled = true
	gem_material.emission = Color(0, 1, 1)
	gem_material.emission_energy_multiplier = 0.8
	gem_material.metallic = 1.0
	gem_material.roughness = 0.1
	gem_mesh_instance.material_override = gem_material

	gem_node.add_child(gem_mesh_instance)

	# Gem light
	var gem_light = OmniLight3D.new()
	gem_light.light_color = Color(0, 1, 1)
	gem_light.light_energy = 2.0
	gem_light.omni_range = 15.0
	gem_node.add_child(gem_light)

	# Ring
	var ring = MeshInstance3D.new()
	var ring_mesh = TorusMesh.new()
	ring_mesh.inner_radius = 1.3
	ring_mesh.outer_radius = 1.5
	ring.mesh = ring_mesh

	var ring_material = StandardMaterial3D.new()
	ring_material.albedo_color = Color(0, 1, 1)
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.albedo_color.a = 0.4
	ring.material_override = ring_material
	ring.rotation_degrees = Vector3(90, 0, 0)

	gem_node.add_child(ring)

	# Position gem
	var x_position = (randf() - 0.5) * (SLOPE_WIDTH - 4)
	gem_node.position = Vector3(x_position, 2, z_position)

	add_child(gem_node)
	gems.append({
		"node": gem_node,
		"mesh": gem_mesh_instance,
		"light": gem_light,
		"ring": ring,
		"x": x_position,
		"z": z_position,
		"collected": false,
		"rotation": 0.0
	})

func _process(delta):
	var scroll_speed = game_manager.get_scroll_speed()
	var player_z = player.position.z

	# Spawn new gems ahead of the player
	while furthest_gem_z > player_z - GEM_SPAWN_AHEAD:
		furthest_gem_z -= GEM_SPAWN_DISTANCE
		create_gem(furthest_gem_z)

	# Move and animate gems, and cleanup old ones
	for i in range(gems.size() - 1, -1, -1):
		var gem = gems[i]
		if not gem.collected:
			gem.node.position.z += scroll_speed
			gem.z = gem.node.position.z

			# Rotate gem
			gem.rotation += 0.03
			gem.mesh.rotation.y = gem.rotation
			gem.mesh.rotation.x = sin(gem.rotation) * 0.2

			# Rotate ring in opposite direction
			gem.ring.rotation.z = -gem.rotation * 0.5

			# Bob up and down
			var bob_height = 2.0 + sin(gem.rotation * 2) * 0.5
			gem.node.position.y = bob_height

			# Pulse the light intensity
			gem.light.light_energy = 2.0 + sin(gem.rotation * 3) * 0.5

			# Cleanup gems that scrolled far past the player
			if gem.z > player_z + GEM_CLEANUP_DISTANCE:
				gem.node.queue_free()
				gems.remove_at(i)

	# Check collisions
	check_collisions()

func check_collisions():
	if not game_manager.is_playing or game_manager.game_over or game_manager.won or game_manager.is_paused:
		return

	var player_x = player.get_player_x()
	var player_z = player.position.z

	for gem in gems:
		if not gem.collected:
			var dx = gem.x - player_x
			var dz = gem.z - player_z
			var distance = sqrt(dx * dx + dz * dz)

			if distance < game_manager.GEM_COLLISION_RADIUS:
				collect_gem(gem)
				break

func collect_gem(gem):
	gem.collected = true
	game_manager.collect_gem()

	# Animate gem collection
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(gem.node, "position:y", gem.node.position.y + 10, 0.5)
	tween.tween_property(gem.mesh, "scale", Vector3(0.1, 0.1, 0.1), 0.5)
	tween.tween_property(gem.ring, "scale", Vector3(2, 2, 2), 0.5)
	tween.tween_property(gem.light, "light_energy", 0.0, 0.5)

	tween.finished.connect(func(): gem.node.queue_free())

	print("Gem collected! Total: ", game_manager.gems_collected)

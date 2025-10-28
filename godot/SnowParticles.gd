extends GPUParticles3D

func _ready():
	# Configure snow particles
	amount = 1000
	lifetime = 10.0
	explosiveness = 0.0
	randomness = 0.5
	visibility_aabb = AABB(Vector3(-30, -5, -80), Vector3(60, 55, 100))

	# Create particle material
	var particle_material = ParticleProcessMaterial.new()

	# Emission
	particle_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_material.emission_box_extents = Vector3(30, 25, 50)

	# Direction and spread
	particle_material.direction = Vector3(0, -1, 0.3)
	particle_material.spread = 20.0
	particle_material.initial_velocity_min = 1.0
	particle_material.initial_velocity_max = 3.0

	# Gravity
	particle_material.gravity = Vector3(0, -0.5, 0)

	# Scale
	particle_material.scale_min = 0.2
	particle_material.scale_max = 0.4

	process_material = particle_material

	# Create draw pass (what the particles look like)
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(0.3, 0.3)

	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true

	draw_pass_1 = quad_mesh
	draw_pass_1.material = material

	emitting = true

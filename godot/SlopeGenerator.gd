extends Node3D

const SLOPE_SEGMENT_LENGTH = 50.0
const SLOPE_WIDTH = 30.0
const NUM_SEGMENTS = 10

var slope_segments = []
var game_manager: Node

func _ready():
	game_manager = get_node("/root/Main/GameManager")
	generate_initial_slope()

func generate_initial_slope():
	for i in range(NUM_SEGMENTS):
		create_slope_segment(i)

func create_slope_segment(index: int):
	var mesh_instance = MeshInstance3D.new()

	# Create plane mesh
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(SLOPE_WIDTH, SLOPE_SEGMENT_LENGTH)
	plane_mesh.subdivide_width = 20
	plane_mesh.subdivide_depth = 20

	mesh_instance.mesh = plane_mesh

	# Create material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.roughness = 0.9
	material.metallic = 0.1
	mesh_instance.material_override = material

	# Position the segment
	mesh_instance.position = Vector3(0, 0, -index * SLOPE_SEGMENT_LENGTH)
	mesh_instance.rotation_degrees = Vector3(-90, 0, 0)

	add_child(mesh_instance)
	slope_segments.append(mesh_instance)

	return mesh_instance

func _process(delta):
	var scroll_speed = game_manager.get_scroll_speed()

	# Move slope segments
	for segment in slope_segments:
		segment.position.z += scroll_speed

		# If segment is behind camera, move it to the front
		if segment.position.z > 25:
			segment.position.z -= slope_segments.size() * SLOPE_SEGMENT_LENGTH

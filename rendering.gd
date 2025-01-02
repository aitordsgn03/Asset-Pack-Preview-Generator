# preview_generator.gd
extends Node3D

@onready var camera = $SubViewport/Camera3D
@onready var model_root = $SubViewport/ModelRoot
@onready var light = $SubViewport/DirectionalLight3D
@onready var sub_viewport = $SubViewport



var current_model: Node3D = null
@export var resolution = 64
@export var padding_factor = 1.2
var output_directory = "res://preview_images/"
@export var transparent_background = true

var supported_extensions = [".gltf",".glb",".fbx",".obj"]
var processing_errors = []

func _ready():
	print("Starting initialization...")
	
	# Check if all required nodes exist
	if !check_required_nodes():
		push_error("Required nodes are missing!")
		return
		
	# Configure viewport for 128x128 images
	print("Configuring viewport...")
	sub_viewport.size = Vector2(128, 128)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sub_viewport.transparent_bg = transparent_background
	sub_viewport.debug_draw = SubViewport.DEBUG_DRAW_DISABLED	
	# Set up the camera and light
	print("Setting up camera and light...")
	setup_isometric_camera()
	
	# Ensure output directory exists
	print("Creating output directory...")
	if !create_output_directory():
		push_error("Failed to create output directory!")
		get_tree().quit()
		return
	
	# Start processing models
	print("Starting model processing...")
	process_models()

func check_required_nodes() -> bool:
	var missing_nodes = []
	if !camera:
		missing_nodes.append("Camera3D")
	if !model_root:
		missing_nodes.append("ModelRoot")
	if !light:
		missing_nodes.append("DirectionalLight3D")
	if !sub_viewport:
		missing_nodes.append("SubViewport")
	
	if missing_nodes.size() > 0:
		push_error("Missing required nodes: " + str(missing_nodes))
		return false
	return true

func create_output_directory() -> bool:
	var dir = DirAccess.open("res://")
	if dir:
		if not dir.dir_exists("preview_images"):
			var err = dir.make_dir("preview_images")
			if err != OK:
				push_error("Failed to create preview_images directory: " + str(err))
				return false
		return true
	push_error("Failed to access project directory")
	return false

func setup_isometric_camera():
	print("Camera setup - Before:")
	print("  Position: ", camera.position)
	print("  Rotation: ", camera.rotation_degrees)
	
	# Ajustamos los ángulos para una vista más suave
	# -35.264 era demasiado picado, lo reducimos a -20
	# Mantenemos los 45 grados en Y para mantener algo de la vista lateral
	camera.rotation_degrees = Vector3(-20, 45, 0)
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 60  # Reducido de 75 para una vista más natural
	
	print("Camera setup - After:")
	print("  Position: ", camera.position)
	print("  Rotation: ", camera.rotation_degrees)

func calculate_camera_distance(aabb: AABB) -> float:
	var diagonal = aabb.size.length()
	var fov_rad = deg_to_rad(camera.fov)
	# Ajustamos la distancia para compensar el nuevo ángulo
	return (diagonal * 0.6 * padding_factor) / tan(fov_rad * 0.5)

func process_models():
	print("Starting process_models...")
	await process_all_models("res://models/")
	print_processing_results()
	get_tree().quit()

func process_all_models(path: String):
	print("Processing directory: " + path)
	var dir = DirAccess.open(path)
	if not dir:
		push_error("Failed to open directory: " + path)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = path + file_name
		
		if dir.current_is_dir() and file_name != "." and file_name != "..":
			print("Entering directory: " + full_path)
			await process_all_models(full_path + "/")
		else:
			var extension = file_name.get_extension().to_lower()
			if "." + extension in supported_extensions:
				print("Processing model: " + full_path)
				var error = await load_and_capture_model(full_path)
				if error != "":
					print("Error processing model: " + error)
					processing_errors.append({"file": full_path, "error": error})
				else:
					print("Successfully processed model: " + full_path)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()


func print_processing_results():
	print("\nProcessing completed!")
	if processing_errors.size() > 0:
		print("\nErrors encountered:")
		for error in processing_errors:
			print("- " + error.file + ": " + error.error)
	else:
		print("No errors encountered.")

func load_and_capture_model(path: String) -> String:
	print("Loading model: " + path)
	
	# Clear previous model
	if current_model:
		current_model.queue_free()
	
	# Load the model
	var model_scene = load(path)
	if not model_scene:
		push_error("Failed to load model: " + path)
		return "Failed to load model: " + path
	
	print("Model loaded, instantiating...")
	
	# Instance the model
	current_model = model_scene.instantiate()
	if not current_model:
		push_error("Failed to instance model: " + path)
		return "Failed to instance model: " + path
	
	model_root.add_child(current_model)
	print("Model instantiated")
	
	# Calculate AABB and vertex count
	var aabb = AABB()
	var vertex_count = 0
	
	print("Calculating model metrics...")
	for child in get_all_mesh_instances(current_model):
		if child is MeshInstance3D:
			if aabb.size == Vector3.ZERO:
				aabb = child.get_aabb()
			else:
				aabb = aabb.merge(child.get_aabb())
			
			if child.mesh:
				vertex_count += get_mesh_vertex_count(child.mesh)
	
	if aabb.size == Vector3.ZERO:
		push_error("No valid meshes found in model: " + path)
		return "No valid meshes found in model: " + path
	
	print("Model metrics calculated:")
	print("  AABB size: ", aabb.size)
	print("  Vertex count: ", vertex_count)
	
	# Position model at origin
	current_model.position = -aabb.position - aabb.size / 2
	
	# Calculate and set camera position without changing rotation
	var camera_distance = calculate_camera_distance(aabb)
	var x_offset = camera_distance / sqrt(3)
	var y_offset = camera_distance / (sqrt(3) * 2)
	var z_offset = camera_distance / sqrt(3)
	camera.position = Vector3(x_offset, y_offset, z_offset)
	
	print("Camera positioned at: ", camera.position)
	
	# Wait frames for rendering
	print("Waiting for frames...")
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Capture and save
	var model_name = path.get_file().get_basename()
	print("Capturing viewport for: " + model_name)
	if not capture_viewport(model_name):
		push_error("Failed to save preview image: " + path)
		return "Failed to save preview image: " + path
	
	# Store vertex count in a temporary file
	print("Saving metadata...")
	var metadata = FileAccess.open("res://preview_images/" + model_name + ".meta", FileAccess.WRITE)
	if metadata:
		metadata.store_string(str(vertex_count))
		print("Metadata saved")
	
	return ""

func get_all_mesh_instances(node: Node, meshes: Array = []) -> Array:
	if node is MeshInstance3D:
		meshes.append(node)
	for child in node.get_children():
		get_all_mesh_instances(child, meshes)
	return meshes

func get_mesh_vertex_count(mesh: Mesh) -> int:
	return mesh.get_faces().size() * 3

func capture_viewport(model_name: String) -> bool:
	print("Starting viewport capture...")
	
	# Get the viewport texture
	var viewport_texture = sub_viewport.get_texture()
	if not viewport_texture:
		push_error("Failed to get viewport texture")
		return false
	
	print("Got viewport texture")
	var image = viewport_texture.get_image()
	if not image:
		push_error("Failed to get image from viewport texture")
		return false
	
	print("Got image from viewport")
	
	# Resize to 128x128
	image.resize(128, 128, Image.INTERPOLATE_BILINEAR)
	print("Resized image")
	
	# Save the image
	var output_path = output_directory + model_name + ".png"
	var err = image.save_png(output_path)
	if err != OK:
		push_error("Failed to save image: " + str(err))
		return false
	
	print("Saved preview: " + output_path)
	return true

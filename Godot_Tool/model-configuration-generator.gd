extends Node

@export var pack_name = "YourPackNameHere"
@export var version = "0.1.0"
@export var author = "AuthorNameHere"
@export var description = "A detailed description of your asset pack goes here."
@export var license = "Open Source"
@export var website = "https://yourwebsite.com/"
@export var license_url = "https://opensource.org/licenses/MIT"
@export var preview_image = "preview_image.png"
@export_group("File Generation")
@export var json_generation = true
@export var license_generation = true
@export var html_generation = true

var total_models = 0
var total_animations = 0
var textures_data = []
var models_data = []


func _ready():
	if json_generation:
		generate_model_config()

	if license_generation:
		generate_license_file()

	if html_generation:
		generate_html_file()
	
func generate_model_config():
	textures_data.clear()  # Limpia datos previos
	models_data.clear()    # Limpia datos previos
	var dir = DirAccess.open("res://models/")
	var texturesdir = DirAccess.open("res://textures/")
	
	if dir:
		scan_directory("res://models/", models_data)
		scan_directory_textures("res://textures/", textures_data)
		
		# Save the configuration
		var config = {
			"models": models_data,
			"textures": textures_data,
			"generated_at": Time.get_datetime_string_from_system(),
			"pack_name": pack_name,
			"author": author,
			"description": description,
			"license": license,
			"stats": {
				"total_models": total_models,
				"total_animations": total_animations
			},
			"pack_preview_image":preview_image
		}
		
		var json_string = JSON.stringify(config, "  ")
		var file = FileAccess.open("res://model_config.json", FileAccess.WRITE)
		if file:
			file.store_string(json_string)
			print("Generated model configuration file")
			print("Processed %d models with %d total animations" % [total_models, total_animations])
		else:
			push_error("Failed to create model_config.json")

func analyze_model(path: String) -> Dictionary:
	var scene = load(path) as PackedScene
	if not scene:
		return {}
	
	var model_info = {}
	var root = scene.instantiate()
	
	# Count meshes
	var mesh_instances = []
	find_nodes_of_type(root, "MeshInstance3D", mesh_instances)
	model_info["mesh_count"] = len(mesh_instances)
	
	# Get mesh names
	var mesh_names = []
	for mesh_instance in mesh_instances:
		if mesh_instance.mesh and not mesh_instance.name in mesh_names:
			mesh_names.append(mesh_instance.name)
	
	# Analyze animations
	var animation_player = find_node_of_type(root, "AnimationPlayer")
	if animation_player:
		var animation_list = animation_player.get_animation_list()
		model_info["has_animations"] = true
		model_info["animation_count"] = len(animation_list)
		total_animations += len(animation_list)
	else:
		model_info["has_animations"] = false
		model_info["animation_count"] = 0
	
	# Get materials
	var materials = []
	for mesh_instance in mesh_instances:
		if mesh_instance.get_surface_override_material_count() > 0:
			for i in range(mesh_instance.get_surface_override_material_count()):
				var material = mesh_instance.get_surface_override_material(i)
				if material and not material.resource_name in materials:
					materials.append(material.resource_name)
	
	model_info["materials"] = materials
	
	root.queue_free()
	return model_info

func find_nodes_of_type(node: Node, type: String, result: Array):
	if node.is_class(type):
		result.append(node)
	for child in node.get_children():
		find_nodes_of_type(child, type, result)

func find_node_of_type(node: Node, type: String) -> Node:
	if node.is_class(type):
		return node
	for child in node.get_children():
		var found = find_node_of_type(child, type)
		if found:
			return found
	return null

func scan_directory(path: String, models_data: Array):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			var full_path = path + file_name
			
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				scan_directory(full_path + "/", models_data)
			elif file_name.get_extension().to_lower() in ["gltf","glb","fbx","obj"]:
				total_models += 1
				var model_name = file_name.get_basename()
				var vertex_count = 0
				
				# Read vertex count from metadata file
				var meta_path = "res://preview_images/" + model_name + ".meta"
				var meta_file = FileAccess.open(meta_path, FileAccess.READ)
				if meta_file:
					vertex_count = meta_file.get_as_text().to_int()
					meta_file.close()
					# Clean up metadata file
					DirAccess.remove_absolute(meta_path)
				
				# Analyze model and get additional information
				var model_info = analyze_model(full_path)
				
				var model_data = {
					"name": model_name,
					"path": full_path.replace("res://", ""),
					"preview_image": "preview_images/" + model_name + ".png",
					"vertex_count": vertex_count,
					"mesh_count": model_info.get("mesh_count", 0),
					"has_animations": model_info.get("has_animations", false),
					"animation_count": model_info.get("animation_count", 0),
				}
				
				models_data.append(model_data)
			
			file_name = dir.get_next()
		
		dir.list_dir_end()

func scan_directory_textures(path: String, textures_data: Array):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			var full_path = path + file_name
			
			if dir.current_is_dir() and file_name != "." and file_name != "..":
				scan_directory(full_path + "/", textures_data)
			elif file_name.get_extension().to_lower() in ["png","jpg","jpeg"]:
				var model_name = file_name.get_basename()
				
				textures_data.append({
					"name": model_name,
					"path": full_path.replace("res://", ""),
				})
			
			file_name = dir.get_next()
		
		dir.list_dir_end()
	print("Generated Textures Data")
#License generation
func generate_license_file():
	var date_obj = Time.get_datetime_dict_from_system()
	var formatted_date = "%02d-%02d-%04d %02d:%02d" % [
		date_obj["day"],
		date_obj["month"],
		date_obj["year"],
		date_obj["hour"],
		date_obj["minute"]
	]

	var content = """
		{pack_name} ({version})
	Created/distributed by {author} ({website})
	Creation date: {date}

			------------------------------
	License: ({license})
	{license_url}

	Support by crediting '{author}' or '{website}' (this is not a requirement)
			------------------------------
	• Website : {website}


	• Twitter : https://x.com/reyortegaitor
	• Itch.io : https://aitordsgn.itch.io/
	• Website : {website}
	""".strip_edges()

	content = content.format({
		"pack_name": pack_name,
		"version": version,
		"author": author,
		"website": website,
		"date": formatted_date,
		"license":license,
		"license_url": license_url
	})

	var file = FileAccess.open("res://license.txt", FileAccess.WRITE)
	if file:
		file.store_string(content)
		print("Generated license.txt file")
	else:
		push_error("Failed to create license.txt")

func generate_html_file():
	print("Generating HTML file...")
	var html_content = """
		<!doctype html>
		<html lang="en">
		<head>
			<meta charset="utf-8">
			<title>%s</title>
			<meta name="description" content="Game assets overview">
			<meta name="author" content="%s">
			<style>
			  :root {
				/* Principal Colors */
				--color-background: #171b21;
				--color-surface: #1e242c;
				--color-surface-alt: #2f333a;
				--color-text-primary: #ffffff;
				--color-text-secondary: #d7d9da;
				--color-accent: #ffbe07;

				/* Shadows */
				--shadow-sm: 0px 1px 2px rgba(0, 0, 0, 0.7);
				--shadow-md: 0px 2px 4px rgba(0, 0, 0, 0.1);
				--shadow-lg: 0px 4px 6px rgba(0, 0, 0, 0.1);
				}
				body {
				font-family: system-ui, sans-serif;
				font-size: 0.9em;
				font-weight: 600;
				color: var(--color-text-secondary);
				background-color: var(--color-background);
				margin: 2em 0;
				overflow-y: scroll;
				transition:
					background-color 0.5s ease,
					color 0.5s ease;
				width: 90vw;
				margin: 0 auto;
				}

				h1 {
				color: var(--color-text-primary);
				font-size: 2.5em;
				margin: 1em auto;
				padding-top: 0.5em;
				text-align: center;
				}

				p {
				line-height: 1.6;
				font-size: 1em;
				}

				a {
				color: var(--color-text-secondary);
				text-decoration: none;
				font-weight: bold;
				border-bottom: 2px solid transparent;
				transition:
					color 0.2s,
					border-color 0.2s;
				}

				a:hover {
				color: var(--color-accent);
				border-color: var(--color-accent);
				}

				.container {
				max-width: 1120px;
				margin: 0 auto;
				padding: 0.5em;
				border-radius: 0.5em;
				}

				.container.header {
				text-align: center;
				}

				.container.footer {
				margin-top: 1em;
				margin-bottom: 1em;
				text-align: center;
				}

				.package {
				position: relative;
				display: inline-flex;
				flex-direction: column;
				align-items: center;
				justify-content: center;
				width: 25vw;
				max-width: 120px;
				margin: 0.5em;
				text-align: center;
				font-size: 12px;
				color: #d7d9da;
				text-decoration: none;
				}

				.package img {
				background-color: var(--color-surface-alt);
				padding: 8px 18px;
				border-radius: 4px;
				width: 64px;
				box-shadow: var(--shadow-lg);
				transition: transform 0.2s ease-in-out;
				}

				.package img:hover {
				transform: scale(1.1);
				background-color: #ececec;
				}

				.package .animated {
				position: absolute;
				top: 10vw;
				left: 1.5em;
				transform: translateY(-50vh);
				color: var(--color-background);
				background-color: var(--color-accent);
				padding: 1px 5px;
				text-transform: uppercase;
				font-size: 10px;
				font-weight: bold;
				border-radius: 2px;
				pointer-events: none;
				}

				.model-info {
				position: absolute;
				bottom: -20px;
				left: 50vw;
				transform: translateX(-50vw);
				display: flex;
				gap: 0.5em;
				font-size: 10px;
				}

				.model-info span {
				background-color: var(--color-surface-alt);
				padding: 2px 6px;
				border-radius: 3px;
				}

				.data {
				color: var(--color-background);
				background-color: var(--color-text-secondary);
				padding: 0.3em 0.7em;
				border-radius: 0.2em;
				font-size: 1em;
				margin-right: 0.5em;
				text-decoration: none;
				transition: background-color 0.2s ease-in-out;
				}

				.data:hover {
				background-color: var(--color-accent);
				color: var(--color-background);
				}

				.swatch {
				display: inline-block;
				width: 16px;
				height: 16px;
				vertical-align: text-top;
				border-radius: 0.2em;
				margin-right: 8px;
				box-shadow: var(--shadow-sm);
				background-size: cover;
				}
				.footer {
				margin-top: 1em;
				text-align: center;
				}
			</style>
		</head>
		<body>
			<div class='container header'><h1>%s</h1></div>
			<div class='container content'>
				<p><strong>Information</strong></p>
				<p>Hover over models to show details. Find more details on the <a target='_blank' href='%s'>official website</a>.</p>
				<p>
					<span class='data'><strong>Total models:</strong> %d×</span>
					<span class='data'><strong>Total animations:</strong> %d×</span>
				</p>
			</div>
			<div class='container content'>
				<p><strong>Textures</strong></p>
				%s
			</div>
			<div class='container content'>
				<p style='margin-bottom:2em'><strong>Models</strong></p>
				%s
			</div>
			<div class='clear'></div>
			<div class='container footer'>
				Find more assets at <a href='%s'>%s</a><br>
				License: <a href='%s'>%s</a>
			</div>
		</body>
		</html>
	""" % [
		pack_name, author, pack_name, website,
		total_models, total_animations,
		get_textures_html(), get_models_html(),
		website, website, license_url, license
	]

	print("HTML content generated successfully.")

	var file = FileAccess.open("res://overview.html", FileAccess.WRITE)
	if file:
		file.store_string(html_content)
		print("Generated overview.html file")
	else:
		push_error("Failed to create overview.html")

func get_textures_html() -> String:
	var textures_html = ""
	for texture in textures_data:
		textures_html += "<p><a href='%s' target='_blank' class='data no-padding'><span class='swatch' style='background-image: url(\"%s\")'></span>%s</a></p>\n" % [
			texture.path, texture.path, texture.name
		]
	return textures_html

func get_models_html() -> String:
	var models_html = ""
	for model in models_data:
		models_html += "<div title='%d vertices • %d animation(s)' class='package'><img src='%s'/><br>%s</div>\n" % [
			model.vertex_count, model.animation_count,
			model.preview_image, model.name
		]
	return models_html

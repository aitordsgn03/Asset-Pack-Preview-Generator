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
				# Llamar recursivamente a scan_directory_textures, no a scan_directory
				scan_directory_textures(full_path + "/", textures_data)
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

# También necesitamos actualizar el CSS para que las texturas se muestren correctamente
func generate_html_file():
	print("Generating HTML file...")
		# Obtener primero los contenidos HTML de texturas y modelos
	var textures_html_content = get_textures_html()
	var models_html_content = get_models_html()
	var html_content = """
		<!doctype html>
			<html lang="en">
			  <head>
				<meta charset="utf-8" />
				<title>{pack_name}</title>
				<meta name="description" content="Game assets overview" />
				<meta name="author" content="{author}" />
				<style>
				/* Custom Properties */
				:root {
				/* Colores principales */
				--color-background: #f0fdf9;
				--color-surface: #ffffff;
				--color-surface-alt: #f1f9f7;
				--color-text-primary: #064e3b;
				--color-text-secondary: #047857;
				--color-accent: #059669;
				--color-accent-light: #d1fae5;

				/* Sombras */
				--shadow-sm: 0 1px 2px rgba(0, 0, 0, 0.05);
				--shadow-md:
					0 4px 6px rgba(0, 0, 0, 0.05), 0 1px 3px rgba(0, 0, 0, 0.1);
				--shadow-lg:
					0 10px 15px -3px rgba(0, 0, 0, 0.1),
					0 4px 6px -2px rgba(0, 0, 0, 0.05);

				/* Otros */
				--border-radius: 0.75rem;
				}

				/* Base Styles */
				body {
				font-family:
					system-ui,
					-apple-system,
					BlinkMacSystemFont,
					"Segoe UI",
					Roboto,
					sans-serif;
				font-size: 0.9em;
				font-weight: 600;
				color: var(--color-text-secondary);
				background-color: var(--color-background);
				margin: 0 auto;
				overflow-y: scroll;
				transition:
					background-color 0.5s ease,
					color 0.5s ease;
				width: 90%;
				}

				h1 {
				color: var(--color-text-primary);
				font-size: 3rem;
				font-weight: 800;
				margin-bottom: 1.5rem;
				line-height: 1.1;
				text-align: center;
				}

				h2 {
				font-size: 1.5rem;
				font-weight: 700;
				margin: 0;
				color: var(--color-text-primary);
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

				/* Container Styles */
				.container {
				max-width: 1200px;
				margin: 0 auto;
				padding: 0 1rem;
				}

				.container.header {
				text-align: center;
				}

				.container.footer {
				margin: 1em auto;
				text-align: center;
				}

				/* Hero Section */
				.hero {
				position: relative;
				padding: 5rem 1rem;
				text-align: center;
				overflow: hidden;
				}

				.hero-content {
				position: relative;
				z-index: 1;
				max-width: 800px;
				margin: 0 auto;
				}

				.hero-description {
				color: var(--color-text-secondary);
				font-size: 1.25rem;
				max-width: 600px;
				margin: 0 auto;
				line-height: 1.6;
				}

				/* Badge Styles */
				.badge {
				display: inline-flex;
				align-items: center;
				gap: 0.5rem;
				background-color: var(--color-accent-light);
				color: var(--color-accent);
				font-weight: 600;
				font-size: 0.875rem;
				padding: 0.5rem 1rem;
				border-radius: 9999px;
				}

				.badge-icon,
				.button-icon {
				width: 1rem;
				height: 1rem;
				}

				.animated-badge {
				position: absolute;
				top: 0.5rem;
				right: 0.5rem;
				background-color: var(--color-accent);
				color: white;
				font-size: 0.625rem;
				font-weight: 700;
				padding: 0.25rem 0.5rem;
				border-radius: 0.25rem;
				z-index: 1;
				}

				/* Section Styles */
				section {
				background-color: var(--color-surface);
				border-radius: var(--border-radius);
				padding: 2rem;
				margin-bottom: 2rem;
				box-shadow: var(--shadow-md);
				border: 1px solid rgba(10, 150, 105, 0.1);
				}

				.section-header {
				display: flex;
				align-items: center;
				margin-bottom: 1.5rem;
				color: var(--color-text-primary);
				}

				.section-icon {
				margin-right: 0.75rem;
				color: var(--color-accent);
				}

				.info-text {
				color: var(--color-text-secondary);
				margin-bottom: 1.5rem;
				line-height: 1.6;
				}

				/* Stats Styles */
				.stats-container {
				display: flex;
				flex-wrap: wrap;
				gap: 1rem;
				}

				.stat-badge,
				.stat {
				display: inline-flex;
				align-items: center;
				gap: 0.5rem;
				background-color: var(--color-surface-alt);
				color: var(--color-text-secondary);
				border-radius: 0.5rem;
				font-size: 0.875rem;
				}

				.stat-badge {
				padding: 0.625rem 1rem;
				}

				.stat {
				gap: 0.375rem;
				padding: 0.375rem 0.75rem;
				border-radius: 0.375rem;
				font-weight: 500;
				}

				.stat-icon {
				color: var(--color-accent);
				}

				/* Texture Styles */
				.textures-container {
				display: flex;
				flex-wrap: wrap;
				gap: 1rem;
				}

				.texture-card {
				display: flex;
				align-items: center;
				gap: 0.75rem;
				background-color: var(--color-surface-alt);
				padding: 0.625rem 1rem;
				border-radius: 0.5rem;
				text-decoration: none;
				color: var(--color-text-secondary);
				transition: all 0.2s ease;
				border: 1px solid transparent;
				}

				.texture-card:hover {
				background-color: var(--color-surface);
				border-color: var(--color-accent);
				transform: translateY(-2px);
				box-shadow: var(--shadow-sm);
				}

				.texture-swatch,
				.swatch {
				border-radius: 0.25rem;
				background-size: cover;
				background-position: center;
				}

				.texture-swatch {
				width: 1.5rem;
				height: 1.5rem;
				border: 1px solid rgba(0, 0, 0, 0.1);
				}

				.swatch {
				display: inline-block;
				width: 16px;
				height: 16px;
				vertical-align: text-top;
				margin-right: 8px;
				box-shadow: var(--shadow-sm);
				}

				.texture-name {
				font-weight: 500;
				font-size: 0.875rem;
				}

				/* Package Styles */
				.package {
				position: relative;
				display: inline-flex;
				flex-direction: column;
				align-items: center;
				justify-content: center;
				width: 25%;
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
				top: 10%;
				left: 1.5em;
				transform: translateY(-50%);
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
				left: 50%;
				transform: translateX(-50%);
				display: flex;
				gap: 0.5em;
				font-size: 10px;
				}

				.model-info span {
				background-color: var(--color-surface-alt);
				padding: 2px 6px;
				border-radius: 3px;
				}

				/* Models Grid Styles */
				.models-grid {
				display: grid;
				grid-template-columns: repeat(auto-fill, minmax(150px, 1fr));
				gap: 1.5rem;
				}

				.model-card,
				.pack-card {
				background-color: var(--color-surface);
				border-radius: var(--border-radius);
				overflow: hidden;
				box-shadow: var(--shadow-sm);
				transition: all 0.3s ease;
				border: 1px solid rgba(10, 150, 105, 0.1);
				position: relative;
				}

				.model-card:hover,
				.pack-card:hover {
				transform: translateY(-5px);
				box-shadow: var(--shadow-md);
				border-color: rgba(10, 150, 105, 0.3);
				}

				.model-image-container {
				position: relative;
				background-color: var(--color-surface-alt);
				padding: 1rem;
				display: flex;
				justify-content: center;
				align-items: center;
				aspect-ratio: 1;
				}

				.model-image,
				.pack-image {
				max-width: 100%;
				max-height: 100%;
				object-fit: contain;
				transition: transform 0.3s ease;
				}

				.model-card:hover .model-image,
				.pack-card:hover .pack-image {
				transform: scale(1.1);
				}

				.model-content,
				.pack-content {
				padding: 1rem;
				}

				.model-name {
				font-size: 0.875rem;
				font-weight: 600;
				margin: 0 0 0.5rem 0;
				color: var(--color-text-primary);
				white-space: nowrap;
				overflow: hidden;
				text-overflow: ellipsis;
				}

				.model-stats,
				.pack-stats {
				display: flex;
				flex-wrap: wrap;
				gap: 0.5rem;
				}

				.model-stat {
				font-size: 0.75rem;
				color: var(--color-text-secondary);
				background-color: var(--color-surface-alt);
				padding: 0.25rem 0.5rem;
				border-radius: 0.25rem;
				white-space: nowrap;
				}

				/* Packs Styles */
				.packs-grid {
				display: grid;
				grid-template-columns: repeat(auto-fill, minmax(320px, 1fr));
				gap: 2rem;
				padding: 1rem 0 4rem;
				}

				.pack-card {
				height: 100%;
				display: flex;
				flex-direction: column;
				}

				.pack-image-container {
				position: relative;
				width: 100%;
				height: 200px;
				background-color: var(--color-surface-alt);
				overflow: hidden;
				}

				.pack-image {
				width: 100%;
				height: 100%;
				object-fit: cover;
				transition: transform 0.5s ease;
				}

				.pack-content {
				padding: 1.5rem;
				flex: 1;
				display: flex;
				flex-direction: column;
				}

				.pack-title {
				color: var(--color-text-primary);
				font-size: 1.25rem;
				font-weight: 700;
				margin: 0 0 0.75rem 0;
				line-height: 1.3;
				}

				.pack-description {
				color: var(--color-text-secondary);
				font-size: 0.95rem;
				margin-bottom: 1.5rem;
				line-height: 1.5;
				/* Add ellipsis for long descriptions */
				display: -webkit-box;
				-webkit-line-clamp: 3;
				-webkit-box-orient: vertical;
				overflow: hidden;
				flex-grow: 1;
				}

				.pack-link {
				display: block;
				text-decoration: none;
				color: inherit;
				height: 100%;
				}

				/* Button Styles */
				.data {
				color: var(--color-background);
				background-color: var(--color-text-secondary);
				padding: 0.3em 0.7em;
				border-radius: 0.2em;
				font-size: 90%;
				margin-right: 0.5em;
				text-decoration: none;
				transition: background-color 0.2s ease-in-out;
				}

				.data:hover {
				background-color: var(--color-accent);
				color: var(--color-background);
				}

				.view-button {
				display: flex;
				align-items: center;
				justify-content: center;
				gap: 0.5rem;
				background-color: var(--color-accent);
				color: white;
				padding: 0.625rem 1rem;
				border-radius: 0.375rem;
				font-weight: 600;
				font-size: 0.875rem;
				transition: background-color 0.2s ease;
				}

				.pack-card:hover .view-button {
				background-color: #047857;
				}

				/* Responsive Styles */
				@media (max-width: 768px) {
				h1 {
					font-size: 2.25rem;
				}

				.hero {
					padding: 3rem 1rem;
				}

				section {
					padding: 1.5rem;
				}

				.models-grid {
					grid-template-columns: repeat(auto-fill, minmax(120px, 1fr));
					gap: 1rem;
				}

				.packs-grid {
					grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
					gap: 1.5rem;
				}

				.package {
					width: 45%;
				}
				}

				@media (max-width: 480px) {
				h1 {
					font-size: 1.875rem;
				}

				.hero-description {
					font-size: 1rem;
				}

				.models-grid {
					grid-template-columns: repeat(auto-fill, minmax(100px, 1fr));
				}

				.model-content {
					padding: 0.75rem;
				}

				.model-name {
					font-size: 0.75rem;
				}

				.model-stat {
					font-size: 0.625rem;
				}

				.packs-grid {
					grid-template-columns: 1fr;
				}

				.package {
					width: 90%;
				}
				}
				</style>
			  </head>
			  <body>
				<div class="page-wrapper" >
				  <header class="hero" >
					<div class="hero-content" >
					  <div class="badge" >
						<svg
						  xmlns="http://www.w3.org/2000/svg"
						  width="24"
						  height="24"
						  fill="none"
						  stroke="currentColor"
						  stroke-linecap="round"
						  stroke-linejoin="round"
						  stroke-width="2"
						  class="icon icon-tabler icons-tabler-outline icon-tabler-package"
						  
						>
						  <path
							stroke="none"
							d="M0 0h24v24H0z"
							
						  ></path>
						  <path
							d="m12 3 8 4.5v9L12 21l-8-4.5v-9L12 3M12 12l8-4.5M12 12v9M12 12 4 7.5M16 5.25l-8 4.5"
							
						  ></path>
						</svg>
						3D Asset Pack
					  </div>
					<h1 >{pack_name}</h1>
					<p class="hero-description" >{description}</p>
					</div>
				  </header>
				  <section class="info-section" >
					<div class="section-header" >
					  <svg
						xmlns="http://www.w3.org/2000/svg"
						width="24"
						height="24"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
						stroke-linecap="round"
						stroke-linejoin="round"
						class="section-icon"
						
					  >
						<path
						  stroke="none"
						  d="M0 0h24v24H0z"
						  fill="none"
						  
						></path>
						<path
						  d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0"
						  
						></path>
						<path d="M12 9h.01" ></path>
						<path d="M11 12h1v4h1" ></path>
					  </svg>
					  <h2 >Information</h2>
					</div>
					<p class="info-text" >
					  If you need help importing the models to your game engine you can
					  contact me if you need.
					</p>
					<div class="stats-container" >
					  <div class="stat-badge" >
						<svg
						  xmlns="http://www.w3.org/2000/svg"
						  width="24"
						  height="24"
						  fill="none"
						  stroke="currentColor"
						  stroke-linecap="round"
						  stroke-linejoin="round"
						  stroke-width="2"
						  class="stat-icon"
						  
						>
						  <path
							stroke="none"
							d="M0 0h24v24H0z"
							
						  ></path>
						  <path d="M14 3v4a1 1 0 0 0 1 1h4" ></path>
						  <path
							d="M17 21H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h7l5 5v11a2 2 0 0 1-2 2zM12 13.5l4-1.5"
							
						  ></path>
						  <path
							d="m8 11.846 4 1.654V18l4-1.846v-4.308L12 10zM8 12v4.2l4 1.8"
							
						  ></path>
						</svg>
			<strong >Total objects:</strong> {total_models}×
					  </div>
					  <div class="stat-badge" >
						<svg
						  xmlns="http://www.w3.org/2000/svg"
						  width="24"
						  height="24"
						  fill="none"
						  stroke="currentColor"
						  stroke-linecap="round"
						  stroke-linejoin="round"
						  stroke-width="2"
						  class="stat-icon"
						  
						>
						  <path
							stroke="none"
							d="M0 0h24v24H0z"
							
						  ></path>
						  <path d="M7 4v16l13-8z" ></path>
						</svg>
			<strong >Total animations:</strong> {total_animations}×
					  </div>
					  <a
						class="stat-badge"
						href="license.txt"
						target="_blank"
						
					  >
						<svg
						  xmlns="http://www.w3.org/2000/svg"
						  width="24"
						  height="24"
						  fill="none"
						  stroke="currentColor"
						  stroke-linecap="round"
						  stroke-linejoin="round"
						  stroke-width="2"
						  class="stat-icon"
						  
						>
						  <path
							stroke="none"
							d="M0 0h24v24H0z"
							
						  ></path>
						  <path
							d="M15 21H6a3 3 0 0 1-3-3v-1h10v2a2 2 0 0 0 4 0V5a2 2 0 1 1 2 2h-2m2-4H8a3 3 0 0 0-3 3v11M9 7h4M9 11h4"
							
						  ></path>
						</svg>
						License
					  </a>
					</div>
				  </section>

				  <section class="textures-section" >
					<div class="section-header" >
					  <svg
						xmlns="http://www.w3.org/2000/svg"
						width="24"
						height="24"
						fill="none"
						stroke="currentColor"
						stroke-linecap="round"
						stroke-linejoin="round"
						stroke-width="2"
						class="section-icon"
						
					  >
						<path
						  stroke="none"
						  d="M0 0h24v24H0z"
						  
						></path>
						<path
						  d="M15 8h.01M3 6a3 3 0 0 1 3-3h12a3 3 0 0 1 3 3v12a3 3 0 0 1-3 3H6a3 3 0 0 1-3-3V6z"
						  
						></path>
						<path
						  d="m3 16 5-5c.928-.893 2.072-.893 3 0l5 5"
						  
						></path>
						<path
						  d="m14 14 1-1c.928-.893 2.072-.893 3 0l3 3"
						  
						></path>
					  </svg>
					  <h2 >Textures</h2>
					</div>
					{textures_html}
				  </section>

				  <section class="models-section" >
					<div class="section-header" >
					  <svg
						xmlns="http://www.w3.org/2000/svg"
						width="24"
						height="24"
						viewBox="0 0 24 24"
						fill="none"
						stroke="currentColor"
						stroke-width="2"
						stroke-linecap="round"
						stroke-linejoin="round"
						class="section-icon"
						
					  >
						<path
						  d="M12.89 1.45l8 4A2 2 0 0 1 22 7.24v9.53a2 2 0 0 1-1.11 1.79l-8 4a2 2 0 0 1-1.79 0l-8-4a2 2 0 0 1-1.1-1.8V7.24a2 2 0 0 1 1.11-1.79l8-4a2 2 0 0 1 1.78 0z"
						  
						></path>
						<polyline
						  points="2.32 6.16 12 11 21.68 6.16"
						  
						></polyline>
						<line
						  x1="12"
						  x2="12"
						  y1="22"
						  y2="11"
						  
						></line>
					  </svg>
					  <h2 >Models</h2>
					</div>
					<div class="models-grid" data-astro-cid-vhql3bsp>
					{models_html}
					</div>
				  </section>
				  <div class="clear"></div>
				  <div class="container footer">
				Find more assets at <a href="{website}">{website}</a><br />
				License: <a href="{license_url}">{license}</a>
				  </div>
				</div>
			  </body>
			</html>

		""" .format({
		"pack_name": pack_name,
		"author": author,
		"description": description,
		"total_models": total_models,
		"total_animations": total_animations,
		"textures_html": textures_html_content,
		"models_html": models_html_content,
		"website": website,
		"license_url": license_url,
		"license": license
	})

	print("HTML content generated successfully.")

	var file = FileAccess.open("res://overview.html", FileAccess.WRITE)
	if file:
		file.store_string(html_content)
		print("Generated overview.html file")
	else:
		push_error("Failed to create overview.html")
		
		
func get_textures_html() -> String:
	var textures_html = "<div class='textures-container' >\n"
	
	if textures_data.size() == 0:
		textures_html += "<p>No textures found</p>\n"
	else:
		for texture in textures_data:
			textures_html += """
			<a
				href="{path}"
				target="_blank"
				rel="noopener noreferrer"
				class="texture-card"
			  >
				<div
				  class="texture-swatch"
				  style="background-image: url({path});"				>
				</div>
				<span class="texture-name" 
				  >{name}</span
				> </a>
			""".format({
				"path": texture.path, 
				"name": texture.name
				})
	
	textures_html += "</div>\n"
	return textures_html

func get_models_html() -> String:
	var models_html = ""
	
	if models_data.size() == 0:
		models_html += "<p>No models found</p>\n"
	else:
		for model in models_data:
			models_html += """
			<div class="model-card" title="{vertex_count} vertex • {mesh_count} group • {animation_count} Animations">
				<div class="model-image-container" >
					<img src="{preview_image}" alt="{name}" loading="lazy" class="model-image" />
				</div>
				<div class="model-content" >
					<h3 class="model-name" >{name}</h3>
					<div class="model-stats">
					<span class="model-stat">{vertex_count} vertex
					</span>
					</div>
				</div>
			</div>
			""".format({
				"name": model.name,
				"preview_image": model.preview_image,
				"vertex_count": model.vertex_count,
				"mesh_count": model.mesh_count,
				"animation_count": model.animation_count
			  })
	return models_html

@tool
extends Node
class_name BlenderCurveImporter

# Configuration
@export_file("*.json") var json_file_path: String = ""
@export var curves_to_import: Array[String] = []
@export_tool_button("Import Curves", "Import") var import_action = import_curves_from_editor

# Signal emitted when import is complete
signal import_completed(curve_count: int)
signal import_failed(error_message: String)

var _json_data: Dictionary = {}

func import_curves_from_editor():
	"""Import curves from the editor button click"""
	if json_file_path == "":
		print("❌ No JSON file path set. Please select a JSON file first.")
		return
	
	print("🔄 Starting import from editor...")
	import_curves_from_json(json_file_path, curves_to_import)

func import_curves_from_json(file_path: String, curve_names: Array[String] = []):
	"""
	Import curves from a Blender JSON export file
	
	Args:
		file_path: Path to the JSON file
		curve_names: Array of curve names to import. If empty, imports all curves
	"""
	
	# Load and parse JSON file
	if not FileAccess.file_exists(file_path):
		emit_signal("import_failed", "JSON file not found: " + file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		emit_signal("import_failed", "Failed to open JSON file: " + file_path)
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json_parse_result = JSON.parse_string(json_string)
	if json_parse_result == null:
		emit_signal("import_failed", "Failed to parse JSON file")
		return
	
	_json_data = json_parse_result
	
	# Validate JSON structure
	if not _validate_json_structure():
		emit_signal("import_failed", "Invalid JSON structure - missing required fields")
		return
	
	# Create parent node if requested
	var parent_node = self
	print("✅ Using existing parent: " + str(parent_node.name if parent_node != null else "null"))

	# Import curves
	var imported_count = 0
	var curves = _json_data.get("curves", [])
	
	for curve_data in curves:
		var curve_name = curve_data.get("name", "UnnamedCurve")
		
		# Check if this curve should be imported
		if curve_names.size() > 0 and curve_name not in curve_names:
			continue
		
		var curve_node = _create_curve_node(curve_data, parent_node)
		if curve_node != null:
			imported_count += 1
	
	emit_signal("import_completed", imported_count)

func _validate_json_structure() -> bool:
	"""Validate that the JSON has the expected structure"""
	if not _json_data.has("metadata"):
		return false
	
	if not _json_data.has("curves"):
		return false
	
	if not _json_data["curves"] is Array:
		return false
	
	return true

func _create_curve_node(curve_data: Dictionary, parent_node: BlenderCurveImporter) -> Path3D:
	"""
	Create a Curve3D node from curve data
	
	Args:
		curve_data: Dictionary containing curve information
		parent_node: Parent node to attach the curve to
	
	Returns:
		The created curve node, or null if creation failed
	"""
	var curve_name = curve_data.get("name", "UnnamedCurve")
	var splines = curve_data.get("splines", [])
	#var dimensions = curve_data.get("dimensions", "3D")
	
	# Create Curve3D resource
	var curve3d = Curve3D.new()
	
	# Process each spline
	for spline_data in splines:
		#var spline_type = spline_data.get("type", "POLY")
		var points = spline_data.get("points", [])
		var is_cyclic = spline_data.get("use_cyclic_u", false)
		
		if points.size() < 2:
			print("Warning: Skipping spline with less than 2 points in curve: " + curve_name)
			continue
		
		# Convert points to Vector3 array
		var curve_points: Array[Vector3] = []
		for point_data in points:
			var co = point_data.get("co", [0, 0, 0])
			# Handle both string and numeric dimensions
			# Swap Y and Z to align Blender coordinates with Godot
			var x = co[0] if co.size() > 0 else 0.0
			var y = co[2] if co.size() > 2 else 0.0  # Blender Z becomes Godot Y
			var z = -co[1] if co.size() > 1 else 0.0  # Blender Y becomes Godot Z
			var point = Vector3(x, y, z)
			curve_points.append(point)
		
		# Add points to Curve3D
		for i in range(curve_points.size()):
			curve3d.add_point(curve_points[i])
			
			# Set tilt if available
			var point_data = points[i]
			if point_data.has("tilt"):
				var tilt = point_data.get("tilt", 0.0)
				curve3d.set_point_tilt(i, tilt)
			
			# Set handle positions for Bezier curves
			if point_data.has("handle_left") and point_data.has("handle_right"):
				var handle_left = point_data.get("handle_left", [0, 0, 0])
				var handle_right = point_data.get("handle_right", [0, 0, 0])
				
				# Convert handle coordinates (swap Y and Z like we did for points)
				var left_x = handle_left[0] if handle_left.size() > 0 else 0.0
				var left_y = handle_left[2] if handle_left.size() > 2 else 0.0  # Blender Z becomes Godot Y
				var left_z = -handle_left[1] if handle_left.size() > 1 else 0.0  # Blender Y becomes Godot Z
				var left_handle = Vector3(left_x, left_y, left_z) - curve_points[i] # Godot expects this to be relative
				
				var right_x = handle_right[0] if handle_right.size() > 0 else 0.0
				var right_y = handle_right[2] if handle_right.size() > 2 else 0.0  # Blender Z becomes Godot Y
				var right_z = -handle_right[1] if handle_right.size() > 1 else 0.0  # Blender Y becomes Godot Z
				var right_handle = Vector3(right_x, right_y, right_z) - curve_points[i] # Godot expects this to be relative
				
				# Set the handle positions
				curve3d.set_point_in(i, left_handle)
				curve3d.set_point_out(i, right_handle)
		
		# Handle cyclic curves
		if is_cyclic and curve_points.size() > 2:
			curve3d.add_point(curve_points[0])  # Close the loop
	
	# Create a Path3D node to visualize the curve
	var path_node = Path3D.new()
	path_node.curve = curve3d
	parent_node.add_child(path_node)
	path_node.set_owner(get_tree().get_edited_scene_root()) 
	path_node.set_name(curve_name + "_Path")
	
	print("Imported curve: " + curve_name + " with " + str(curve3d.get_point_count()) + " points")
	
	return path_node

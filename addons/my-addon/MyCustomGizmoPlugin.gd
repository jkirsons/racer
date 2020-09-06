extends EditorNode3DGizmoPlugin

func get_curve(spatial):
	return spatial.get_node("MainPath").curve

func get_name():
	return "CustomNode"

func _init():
	create_material("main", Color(0,1,0))
	create_material("secondary", Color(0,0,1))
	create_handle_material("handles")

func has_gizmo(spatial):
	if spatial.name == "Track":
		print("Match: "+str(spatial.name))
		return true
	else:
		#print("No Match: "+str(spatial.name))
		return false

func get_forward(curve, index):
	# Gets the forward vector of a curve index
	# Handles nodes with no in/out handles
	var forward = curve.get_point_out(index)
	if forward == Vector3(0, 0, 0):
		if index < curve.get_point_count()-1:
			forward = curve.get_point_position(index+1) - curve.get_point_position(index) 
		else:
			forward = curve.get_point_position(0) - curve.get_point_position(index)
	return forward

func redraw(gizmo):
	gizmo.clear()
	var spatial = gizmo.get_spatial_node()
	var curve = get_curve(spatial)
	
	var lines = PackedVector3Array([Vector3(0,0,0)])
	var lines2 = PackedVector3Array([Vector3(0,0,1)])
	var handles = PackedVector3Array([Vector3(0,0,2)])
	lines.remove(0)
	lines2.remove(0)
	handles.remove(0)
	

	for n in range(0, curve.get_point_count() as int):
		var pos = curve.get_point_position(n)
		var forward  = get_forward(curve, n)
		
		var handle_pos = Vector3(0, 5, 0).rotated(forward.normalized(), -curve.get_point_tilt(n))
		lines.push_back(pos)
		lines.push_back(pos+handle_pos)
		lines.push_back(pos)
		lines.push_back(pos+forward.normalized()*5)
		lines2.push_back(pos)
		lines2.push_back(pos + forward.normalized().cross(Vector3.UP)*5)
		handles.push_back(pos+handle_pos)
	gizmo.add_lines(lines, get_material("main", gizmo), false)
	gizmo.add_lines(lines2, get_material("secondary", gizmo), false)
	gizmo.add_handles(handles, get_material("handles", gizmo))

func get_handle_name( gizmo, index ):
	print("Get Handle Index " + str(index))
	return index
	
func get_handle_value( gizmo, index ):
	print("Get Handle Value - Index " + str(index))
	var spatial = gizmo.get_spatial_node()
	return get_curve(spatial).get_point_tilt(index)

func set_handle ( gizmo, index, camera, point ):
	print("Set Handle Index " + str(index))
	var spatial = gizmo.get_spatial_node()
	var curve = get_curve(spatial)
	
	var forward = get_forward(curve, index)
	var cross = forward.cross(Vector3.UP)
	
	var pos = curve.get_point_position(index)
	
	var p = Plane( pos, pos + cross, pos + Vector3.UP )
	var intersect = p.intersects_ray(camera.project_ray_origin(point),
		camera.project_ray_normal(point))
	
	var intersect_local = intersect - pos

	curve.set_point_tilt(index, 
		intersect_local.angle_to(Vector3.UP) 
		* -sign(intersect_local.dot(cross)))  # give the angle a sign
	
	redraw(gizmo)

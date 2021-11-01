extends EditorNode3DGizmoPlugin

func get_curve(spatial):
	return spatial.get_node("MainPath").curve

func _get_gizmo_name():
	return "RotatePath"

func _init():
	create_material("main", Color(0,1,0))
	create_material("secondary", Color(1,0,1))
	create_material("tertiary", Color(1,0,0))
	create_handle_material("handles")

func _has_gizmo(spatial):
	if spatial.name == "Track":
		print("Gizmo Match: "+str(spatial.name))
		return true
	else:
		#print("Gizmo No Match: "+str(spatial.name))
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

func _redraw(gizmo):
	var spatial = gizmo.get_spatial_node()
	var curve = get_curve(spatial)
	
	var lines = PackedVector3Array([])
	var lines2 = PackedVector3Array([])
	var lines3 = PackedVector3Array([])
	var handles = PackedVector3Array([])
	#var ids = PackedInt32Array([])
	
	#print("Points: " + str(curve.get_point_count()))
	
	for n in range(0, curve.get_point_count() as int):
		var pos = curve.get_point_position(n)
		var forward  = get_forward(curve, n).normalized()
		
		var handle_pos = Vector3(0, 5, 0).rotated(forward, curve.get_point_tilt(n))
		
		var curve_pos = n as float / (curve.get_point_count()-1) * curve.get_baked_length()
		var pos2 = curve.interpolate_baked(curve_pos)
		
		lines.push_back(pos)
		lines.push_back(pos+handle_pos)
		#lines3.push_back(pos)
		#lines3.push_back(pos+forward*5)
		#lines2.push_back(pos2)
		#lines2.push_back(pos2 + Transform3D().looking_at(-forward, curve.interpolate_baked_up_vector(curve_pos, true)) * Vector3(0, 5, 0))
		handles.push_back(pos+handle_pos)
		#ids.push_back(n+1)
		print("Point: " + str(n) + " = " + str(curve_pos) + " Up: " + str(curve.interpolate_baked_up_vector(curve_pos)) + " Up(twist): " + str(curve.interpolate_baked_up_vector(curve_pos, true)))
	gizmo.clear()
	gizmo.add_lines(lines, get_material("main", gizmo), false)
	#gizmo.add_lines(lines2, get_material("secondary", gizmo), false)
	#gizmo.add_lines(lines3, get_material("tertiary", gizmo), false)
	gizmo.add_handles(handles, get_material("handles", gizmo), PackedInt32Array([]))

func _get_handle_name( gizmo, index ):
	#print("Get Handle Index " + str(index))
	return index
	
func _get_handle_value( gizmo, index ):
	#print("Get Handle Value - Index " + str(index))
	var spatial = gizmo.get_spatial_node()
	return get_curve(spatial).get_point_tilt(index)

func _commit_handle ( gizmo, handle_id, restore, cancel ):
	print("Gizmo commit")
	_redraw(gizmo)

func _set_handle ( gizmo, index, camera, point ):
	#print("Set Handle Index " + str(index))
	var spatial = gizmo.get_spatial_node()
	var curve = get_curve(spatial)
	
	var forward = get_forward(curve, index).normalized()
	#if forward == Vector3.ZERO:
	#	forward = Vector3.AXIS_Z
		
	var cross = forward.cross(Vector3.UP)
	
	var pos = curve.get_point_position(index)
	
	var p = Plane( pos, pos + cross, pos + Vector3.UP )
	var intersect = p.intersects_ray(camera.project_ray_origin(point),
		camera.project_ray_normal(point))
	
	var intersect_local = (intersect - pos).normalized()

	curve.set_point_tilt(index, 
		intersect_local.angle_to(Vector3.UP) 
		* sign(intersect_local.dot(cross)))  # give the angle a sign
	
	_redraw(gizmo)

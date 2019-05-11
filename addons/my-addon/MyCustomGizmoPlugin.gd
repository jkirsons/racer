extends EditorSpatialGizmoPlugin

const MyCustomSpatial = preload("res://PathRotation.gd")

func get_name():
	return "CustomNode"

func _init():
	create_material("main", Color(0,1,0))
	create_material("secondary", Color(0,0,1))
	create_handle_material("handles")

func has_gizmo(spatial):
	print(str(spatial))
	return spatial is MyCustomSpatial

func redraw(gizmo):
	gizmo.clear()
	var spatial = gizmo.get_spatial_node()
	var curve = spatial.get_node("Path").curve
	
	var lines = PoolVector3Array()
	var lines2 = PoolVector3Array()
	var handles = PoolVector3Array()

	for n in range(0,curve.get_point_count()):
		var pos = curve.get_point_position(n)
		var forward = curve.get_point_out(n)
		
		# no forward handle
		if forward == Vector3(0, 0, 0):
			if n+1 < curve.get_point_count():
				forward = curve.get_point_position(n+1)
			else:
				forward = curve.get_point_position(0)
		
		var handle_pos = Vector3(0, 5, 0).rotated(forward.normalized(), -curve.get_point_tilt(n))
		lines.push_back(pos)
		lines.push_back(pos+handle_pos)
		#lines.push_back(pos)
		#lines.push_back(pos+curve.get_point_in(n).normalized()*5)
		lines.push_back(pos)
		lines.push_back(pos+forward.normalized()*5)
		lines2.push_back(pos)
		lines2.push_back(pos + forward.normalized().cross(Vector3.UP)*5)
		handles.push_back(pos+handle_pos)
	gizmo.add_lines(lines, get_material("main", gizmo), false)
	gizmo.add_lines(lines2, get_material("secondary", gizmo), false)
	gizmo.add_handles(handles, get_material("handles", gizmo))

func commit_handle ( gizmo, index, restore, cancel=false):
	print("commit")

func get_handle_value( gizmo, index ):
	var spatial = gizmo.get_spatial_node()
	var tilt = spatial.get_node("Path").curve.get_point_tilt(index)
	return tilt
	#return (gizmo.get_spatial_node().global_transform.origin 
	#	+ gizmo.get_spatial_node().global_transform.basis.y).rotated(Vector3.FORWARD,tilt)
	#print("get value") 

func set_handle ( gizmo, index, camera, point ):
	var spatial = gizmo.get_spatial_node()
	var curve = spatial.get_node("Path").curve
	
	var forward = curve.get_point_out(index)
	# no forward handle
	if forward == Vector3(0, 0, 0):
		if index+1 < curve.get_point_count():
			forward = curve.get_point_position(index+1)
		else:
			forward = curve.get_point_position(0)
	
	var pos = curve.get_point_position(index)
	var cross = forward.cross(Vector3.UP)
	
	var p = Plane( pos, pos + cross, pos + Vector3.UP )
	var intersect = p.intersects_ray(camera.project_ray_origin(point),
		camera.project_ray_normal(point))
	
	var intersect_local = intersect - pos

	spatial.get_node("Path").curve.set_point_tilt(index, 
		intersect_local.angle_to(Vector3.UP) 
		* -sign(intersect_local.dot(cross)))  # give the angle a sign
	
	redraw(gizmo)
# you should implement the rest of handle-related callbacks
# (get_handle_name(), get_handle_value(), commit_handle()...)
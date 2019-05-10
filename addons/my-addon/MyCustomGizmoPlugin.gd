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
	print("draw")
	gizmo.clear()
	var spatial = gizmo.get_spatial_node()
	var curve = spatial.get_node("Path").curve
	
	var lines = PoolVector3Array()
	var lines2 = PoolVector3Array()
	var handles = PoolVector3Array()

	for n in range(0,curve.get_point_count()):
		var pos = curve.get_point_position(n)
		lines.push_back(pos)
		lines.push_back(pos+Vector3(0, 5, 0))
		lines.push_back(pos)
		lines.push_back(pos+curve.get_point_in(n))
		lines.push_back(pos)
		lines.push_back(pos+curve.get_point_out(n))
		lines2.push_back(pos)
		lines2.push_back(pos + curve.get_point_out(n).cross(Vector3.UP))
		handles.push_back(pos+Vector3(0, 5, 0))
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
	var pos = curve.get_point_position(index)
	
	var p = Plane( pos, 
		pos + curve.get_point_out(index).cross(Vector3.UP), 
		pos + Vector3.UP )
	var intersect = p.intersects_ray(camera.project_ray_origin(point),
		camera.project_ray_normal(point))
	print("ray: "+str(camera.project_ray_origin(point)) 
		+ " " + str(camera.project_ray_normal(point)))
	print("plane: " + str(p)) 
	
	var intersect_local = intersect - pos
	print("intersect: " + str(intersect)) 
	print("intersect local: " + str(intersect_local))

	spatial.get_node("Path").curve.set_point_tilt(index, 
		intersect_local.angle_to(Vector3.UP) 
		* (intersect_local).normalized().x)  # give the angle a sign
	
# you should implement the rest of handle-related callbacks
# (get_handle_name(), get_handle_value(), commit_handle()...)
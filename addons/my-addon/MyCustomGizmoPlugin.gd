extends EditorSpatialGizmoPlugin

const MyCustomSpatial = preload("res://PathRotation.gd")

func get_name():
    return "CustomNode"

func _init():
    create_material("main", Color(0,1,0))
    create_handle_material("handles")

func has_gizmo(spatial):
    return spatial is MyCustomSpatial

func redraw(gizmo):
	gizmo.clear()
	var spatial = gizmo.get_spatial_node()
	
	var lines = PoolVector3Array()
	var handles = PoolVector3Array()

	var curve = spatial.get_node("Path").curve
	var count = curve.get_point_count()
	for n in range(0,curve.get_point_count()):
		var pos = curve.get_point_position(n)
		lines.push_back(pos)
		lines.push_back(pos+Vector3(0, 5, 0))
		handles.push_back(pos+Vector3(0, 5, 0))
	
	gizmo.add_lines(lines, get_material("main", gizmo), false)
	gizmo.add_handles(handles, get_material("handles", gizmo))

func commit_handle ( gizmo, index, restore, cancel=false):
	print("commit")

func get_handle_value( gizmo, index ):
	var spatial = gizmo.get_spatial_node()
	var tilt = spatial.get_node("Path").curve.get_point_tilt(index)
	return (gizmo.get_spatial_node().global_transform.origin 
		+ gizmo.get_spatial_node().global_transform.basis.y).rotated(Vector3.FORWARD,tilt)
	#print("get value") 

func set_handle ( gizmo, index, camera, point ):
	gizmo.set_hidden( false )
	
	var p = Plane( gizmo.get_spatial_node().global_transform.origin, 
			gizmo.get_spatial_node().global_transform.origin + gizmo.get_spatial_node().global_transform.basis.x,
			gizmo.get_spatial_node().global_transform.origin + gizmo.get_spatial_node().global_transform.basis.y)
	var intersect = p.intersects_ray(camera.project_ray_origin(point),
		camera.project_ray_normal(point))
	print("set value " + str(intersect)) 
	print("index " + str(index))
	var spatial = gizmo.get_spatial_node()
	spatial.get_node("Path").curve.set_point_tilt(index, intersect.angle_to((
		gizmo.get_spatial_node().global_transform.origin 
		+ gizmo.get_spatial_node().global_transform.basis.y)))
	
# you should implement the rest of handle-related callbacks
# (get_handle_name(), get_handle_value(), commit_handle()...)
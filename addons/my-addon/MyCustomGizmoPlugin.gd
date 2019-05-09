extends EditorSpatialGizmoPlugin

const MyCustomSpatial = preload("res://PathRotation.gd")

func get_name():
    return "CustomNode"

func _init():
    create_material("main", Color(0,1,0))
    create_handle_material("handles")

func has_gizmo(spatial):
	print(str(spatial))
	return spatial is MyCustomSpatial

func redraw(gizmo):
	print("draw")
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
	print("add")
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
	var gt = gizmo.get_spatial_node().global_transform
	var p = Plane( gt.origin, gt.origin + gt.basis.x, gt.origin + gt.basis.y)
	var intersect = p.intersects_ray(camera.project_ray_origin(point),
		camera.project_ray_normal(point))
	print("ray: "+str(camera.project_ray_origin(point)) + " " + str(camera.project_ray_normal(point)))
	print("plane: " + str(p)) 
		
	var intersect_local = intersect - gt.origin 
	print("intersect: " + str(intersect)) 
	print("index: " + str(index))
	var spatial = gizmo.get_spatial_node()
	spatial.get_node("Path").curve.set_point_tilt(index, intersect_local.angle_to(Vector3.UP) * -intersect_local.normalized().x)
	
# you should implement the rest of handle-related callbacks
# (get_handle_name(), get_handle_value(), commit_handle()...)
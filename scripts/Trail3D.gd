# Trail3D
# author: miziziziz
# https://github.com/willnationsdev/godot-next/blob/master/addons/godot-next/3d/trail_3d.gd
# brief description: Creates a variable-length trail on an ImmediateGeometry node.
# API details:
# - density_lengthwise: number of vertex loops in trail
# - density_around: number of vertexes in each loop
# - shape: curve used to shape trail, right click on this in inspector to see curve options

extends MeshInstance3D
class_name Trail3D

@export var length : float = 10.0
@export var max_radius = 0.5
@export var density_lengthwise : int = 10
@export var density_around : int = 3
@export_exp_easing("attenuation") var shape : float = 0.5

var points = []
var segment_length = 1.0
var arr_mesh : ArrayMesh

func _ready():
	arr_mesh = ArrayMesh.new()
	
	if length <= 0:
		length = 2
	if density_around < 3:
		density_around = 3
	if density_lengthwise < 2:
		density_lengthwise = 2
	
	segment_length = length / density_lengthwise

	points = points.duplicate()
	for p in density_lengthwise:
		points.append(global_transform.origin)

func _process(_delta):
	#update_trail()
	#render_trail()
	pass
	
func update_trail():
	global_transform.basis = Basis()
	var ind = 0
	var last_p = global_transform.origin
	for p in points:
		var dis = p.distance_to(last_p)
		var seg_len = segment_length
		if ind == 0:
			seg_len = 0.05
		if dis > seg_len:
			p = last_p + (p - last_p) * (1 /  dis) * seg_len
		last_p = p
		points[ind] = p
		ind += 1
	#points = points.duplicate()
	#points.pop_back()
	#points.push_front(last_p)

func render_trail():
	var arr = [9]
	arr.resize(Mesh.ARRAY_MAX)
	var vert = PackedVector3Array()
	while not vert.empty():
		vert.remove(0)
	
	var local_points = [0]
	local_points.clear()
	for p in points:
		local_points.append(p - global_transform.origin)
	var last_p = Vector3()
	var verts = [1]
	verts.clear()
	var ind = 0
	var first_iteration = true
	var last_first_vec = Vector3()
	# create vertex loops around points
	for p in local_points:

		var offset = last_p - p
		if offset == Vector3():
			continue
		var y_vec = offset.normalized() # get vector pointing from this point to last point
		var x_vec = Vector3()
		if first_iteration:
			x_vec = y_vec.cross(y_vec.rotated(Vector3(1.0, 0.0, 0.0), 0.3)) #cross product with random vector to get a perpendicular vector
		else:
			x_vec = y_vec.cross(last_first_vec).cross(y_vec).normalized() # keep each loop at the same rotation as the previous
		var width = max_radius
		if shape != 0:
			width = (1 - ease((ind + 1.0) / density_lengthwise, shape)) * max_radius
		var seg_verts = [3]
		seg_verts.clear()
		var f_iter = true
		for i in range(density_around): # set up row of verts for each level
			var new_vert = p + width * x_vec.rotated(y_vec, i * 2.0 * PI / density_around).normalized()
			if f_iter:
				last_first_vec = new_vert - p
				f_iter = false
			seg_verts.append(new_vert)
		verts.append(seg_verts.duplicate())
		last_p = p
		ind += 1
		first_iteration = false
		
	# create tris
	for j in range(len(verts) - 1):
		var cur = verts[j]
		var nxt = verts[j + 1]
		for i in range(density_around):
			var nxt_i = (i + 1) % density_around
			#order added affects normal
			vert.append(cur[i])
			vert.append(cur[nxt_i])
			vert.append(nxt[i])
			vert.append(cur[nxt_i])
			vert.append(nxt[nxt_i])
			vert.append(nxt[i])
	
	if verts.size() > 1:
		#cap off top
		for i in range(density_around):
			var nxt = (i + 1) % density_around
			vert.append(verts[0][i])
			vert.append(Vector3())
			vert.append(verts[0][nxt])
		
		
		#cap off bottom
		for i in range(density_around):
			var nxt = (i + 1) % density_around
			vert.append(verts[verts.size() - 1][i])
			vert.append(verts[verts.size() - 1][nxt])
			vert.append(last_p)
	
		arr[ArrayMesh.ARRAY_VERTEX] = vert
		arr_mesh.clear_surfaces()
		arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		mesh = arr_mesh

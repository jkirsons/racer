@tool
extends Node3D
class_name PathClone

@export_node_path(Path3D) var parent_path : NodePath
@export var object_res : Mesh

@export_range(0.0, 1.0) var start_pos : float
@export var copies: int = 0
@export_range(0.0, 1.0) var space_between : float

@export var offset : Vector3 = Vector3(0.0,0.0,0.0)
@export var rotate : bool
@export var clamp_to_ground : bool
@export var mirror_x : bool
@export var height_limit : float

var parent_curve : Curve3D

var settings = {}

func get_settings() -> Dictionary:
	var set = {
		start_pos: start_pos,
		copies: copies,
		space_between: space_between,
		offset: offset,
		rotate: rotate,
		clamp_to_ground: clamp_to_ground,
		mirror_x: mirror_x,
		height_limit: height_limit
	}
	return set

# Called when the node enters the scene tree for the first time.
func _ready():
	var parent : Path3D = get_node(parent_path) as Path3D
	parent_curve = parent.curve
	parent.connect("curve_changed", self._on_Path_curve_changed)
	
func _process(delta):
	var set = get_settings()
	if set.hash() != settings.hash():
		settings = set
		update_curve()


func _on_Path_curve_changed():
	update_curve()
	
func update_curve():
#	if !offset:
#		offset = Vector3(0.0,0.0,0.0)
	if !parent_curve:
		parent_curve = get_node(parent_path).curve

	# delete all children
	for child in get_children():
		remove_child(child)
		child.queue_free()
		#child.call_deferred("queue_free")
	
	print("adding copies: " + str(copies))
	
	var i : int = 0
	while i < copies:
	#for i in range(0, copies as int):
		
		var m = MeshInstance3D.new()
		m.set_name(String(name) + "_" + str(i))
		m.set_mesh(object_res)
		add_child(m)
		m.set_owner(get_tree().get_edited_scene_root()) 
		
		
		# position of instance
		var length = parent_curve.get_baked_length()
		var pos = (start_pos + space_between * i) * length 
		if pos > length:
			pos = pos - length
		elif pos < 0:
			pos = pos + length
		
		# position offset
		var forward = Vector3()
		if pos < (length - 0.001):
			forward = (parent_curve.interpolate_baked(pos) - parent_curve.interpolate_baked(pos + 0.001)).normalized()
		else:
			forward = (parent_curve.interpolate_baked(pos - 0.001) - parent_curve.interpolate_baked(pos)).normalized()
		var up = -parent_curve.interpolate_baked_up_vector(pos, true).bounce(Vector3.UP).normalized()
		var right = forward.cross(up)

		m.transform.origin = parent_curve.interpolate_baked(pos) + right * offset.x + up * offset.y + forward * offset.z

		if mirror_x:
			var m2 = m.duplicate()
			m2.transform.origin = parent_curve.interpolate_baked(pos) - right * offset.x + up * offset.y + forward * offset.z
			add_child(m2)
			m2.set_owner(get_tree().get_edited_scene_root()) 
		print("add child " + str(i))
		i += 1

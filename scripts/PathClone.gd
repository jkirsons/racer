@tool
extends Node3D
class_name PathClone

@export_node_path(Path3D) var parent_path : NodePath
@export var object_res : PackedScene
#@export_file var object_path

@export_range(0.0, 1.0) var start_pos : float = 0.0
@export var copies: int = 0
@export_range(0.0, 1.0) var space_between : float = 0.01

@export var offset : Vector3 = Vector3(0.0, 0.0, 0.0)
@export var random_rotate : bool = false
@export var align_to_path : bool = false
@export var clamp_to_ground : bool = false
@export var mirror_x : bool = false
@export var opposite_offset : bool = false
@export var height_limit : float = 0.0

var parent_curve : Curve3D

var settings = {}
var timer : float = 0.0

func get_settings() -> Dictionary:
	var sett = {
		start_pos: start_pos,
		copies: copies,
		space_between: space_between,
		align_to_path: align_to_path,
		offset: offset,
		random_rotate: random_rotate,
		clamp_to_ground: clamp_to_ground,
		mirror_x: mirror_x,
		height_limit: height_limit
	}
	return sett

# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		var parent : Path3D = get_node(parent_path) as Path3D
		parent_curve = parent.curve
		parent.connect("curve_changed", self._on_Path_curve_changed)

func _process(delta):
	if Engine.is_editor_hint():
		var sett = get_settings()
		if sett.hash() != settings.hash():
			settings = sett
			update_curve()
	
	if timer > 0:
		timer -= delta
	if timer < 0:
		update_curve()
		timer = 0

func _on_Path_curve_changed():
	timer = 3.0
	
func update_curve():
#	if !offset:
#		offset = Vector3(0.0,0.0,0.0)
	if !parent_curve:
		parent_curve = get_node(parent_path).curve

	# delete all children
	for child in get_children():
		if "__" in String(child.name):
			remove_child(child)
			child.queue_free()
	
	print(String(self.name) + " - adding copies: " + str(copies))
	#var object_res = load(object_path)
	
	var i : int = 0
	while i < copies:
		
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
		var up = parent_curve.interpolate_baked_up_vector(pos, true)
		#var right = forward.cross(up).normalized()
		
		var m = object_res.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		#m = self.duplicate()
		m.set_name(String(name) + "__" + str(i))
		add_child(m)
		m.set_owner(get_tree().get_edited_scene_root()) 
		
		if align_to_path:
			m.global_transform.basis = Basis.looking_at(-forward, up) #Basis(right, up, forward)#.orthonormalized()
		if random_rotate:
			m.transform = m.transform.rotated(m.transform.basis * Vector3(0.0, 1.0, 0.0), 2.0 * PI * randf())
		m.transform.origin = parent_curve.interpolate_baked(pos) + offset * Basis.looking_at(forward, up)
		
		if mirror_x:
			var m2 = object_res.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
			m2.set_name(String(name) + "__" + str(i) + "_(Mirror)")
			if align_to_path:
				m2.transform.basis = Basis.looking_at(-forward, up) #Basis(right, up, forward).orthonormalized()
			if random_rotate:
				m2.transform = m2.transform.rotated(m2.transform.basis * Vector3(0.0, 1.0, 0.0), 2.0 * PI * randf())
			if !opposite_offset:
				offset.x *= -1
			m2.transform.origin = parent_curve.interpolate_baked(pos) + ( -1 if opposite_offset else 1 ) * offset * Basis.looking_at(forward, up)

			add_child(m2)
			m2.set_owner(get_tree().get_edited_scene_root())

		#print("add child " + str(i))
		i += 1

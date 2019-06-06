tool
extends Area
class_name BoostArea

export var parent_path : NodePath

export var speed = 100
export(float, 0, 1) var start_pos
export var offset : Vector3

var parent_curve : Curve3D

var settings = {}

func get_settings() -> Dictionary:
	var set = {}
	set.start_pos = start_pos
	set.offset = offset
	return set
	
# Called when the node enters the scene tree for the first time.
func _ready():
	connect("body_entered", self, "_on_Area_body_entered")
	
	var parent : Path = get_node(parent_path)
	parent_curve = parent.curve
	parent.connect("curve_changed", self, "_on_Path_curve_changed")	

func _on_Area_body_entered(body):
	if body.name == "Vehicle":
		body.speed = speed;

func _process(delta):
	var set = get_settings()
	if set.hash() != settings.hash():
		settings = set
		update_pos()

func _on_Path_curve_changed():
	update_pos()
	
func update_pos():
	if !parent_curve:
		parent_curve = get_node(parent_path).curve
	
	# position of instance
	var length = parent_curve.get_baked_length()
	var pos = start_pos * length 
	
	# position offset
	var forward = Vector3()
	if pos < (length - 0.001):
		forward = (parent_curve.interpolate_baked(pos) - parent_curve.interpolate_baked(pos + 0.001)).normalized()
	else:
		forward = (parent_curve.interpolate_baked(pos - 0.001) - parent_curve.interpolate_baked(pos)).normalized()
	var up = -parent_curve.interpolate_baked_up_vector(pos, true).bounce(Vector3.UP).normalized()
	var right = forward.cross(up)
	
	global_transform.origin = parent_curve.interpolate_baked(pos) + right * offset.x + up * offset.y + forward * offset.z
	global_transform.basis = Basis(right, up, forward)
@tool
extends Path3D
class_name PathSegment

@export_node_path(Path3D) var parent_path : NodePath
@export var start_node : int = 0
@export var length: int = 1

var parent_curve
var timer : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	var parent : Path3D = get_node(parent_path) as Path3D
	parent.connect("curve_changed", self._on_Path_curve_changed)
	if start_node == null:
		start_node = 0
	
func _on_Path_curve_changed():
	timer = 3.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if !parent_curve:
		var parent : Path3D = get_node(parent_path) as Path3D
		parent_curve = parent.curve
		
	if Engine.is_editor_hint() and (length != curve.get_point_count() or curve.get_point_position(0) != parent_curve.get_point_position(start_node)) and parent_path:
		update_curve(parent_curve)

	if timer > 0:
		timer -= delta
	if timer < 0:
		timer = 0
		update_curve(parent_curve)
		
func update_curve(parent_curve_in : Curve3D):
	print(String(self.name) + " - PathSegment - Curve Updating")
	if length == 0:
		length = parent_curve_in.get_point_count()
	
	
	curve.clear_points()
	for i in range(start_node, (start_node+length)):
		
		var point_out : Vector3 = Vector3.ZERO
		point_out = parent_curve.get_point_out(i)
		if i == start_node+length:
			point_out = Vector3.ZERO
		
		var point_in : Vector3 = Vector3.ZERO
		point_in = parent_curve.get_point_in(i)
		if i == start_node:
			point_in = Vector3.ZERO
		
		curve.add_point(parent_curve.get_point_position(i), point_in, point_out)
		curve.set_point_tilt(i-start_node, parent_curve.get_point_tilt(i))



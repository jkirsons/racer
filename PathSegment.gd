tool
extends Path
class_name PathSegment

export var parent_path : NodePath
export var start_node : int
export var length: int

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.editor_hint and length != curve.get_point_count() and parent_path:
		curve.clear_points()
		var parent : Path = get_node(parent_path)
		var parent_curve = parent.curve
		print(parent_curve)
		for i in range(start_node, (start_node+length)):
			print(i)
			var point_out = parent_curve.get_point_out(i)
			if i == start_node+length:
				point_out = Vector3.ZERO
			
			curve.add_point(parent_curve.get_point_position(i), parent_curve.get_point_in(i), point_out)
			curve.set_point_tilt(i-start_node, parent_curve.get_point_tilt(i))
		curve.



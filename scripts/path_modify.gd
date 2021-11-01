#@tool
extends EditorScript

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _run():
	var current_scene = get_scene()
	var new_curve = Curve3D.new()
	var path : Path3D = current_scene.get_node("Track/MainPath") as Path3D
	for i in range(0, path.curve.get_point_count()):
		new_curve.add_point(path.curve.get_point_position(i)*3)
	path.curve = new_curve
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

@tool
extends Node

@export_node_path("Path3D") var parent_path : NodePath

var parent_curve

# Called when the node enters the scene tree for the first time.
func _ready():
	var path : Path3D = get_node(parent_path) as Path3D
	if path:
		var curve = path.curve
		for index in range(0, curve.get_point_count() as int):
			print("Node: " + str(index))
			print("Tilt: " + str(curve.get_point_tilt(index)))
			print("Pos: " + str(curve.get_point_position(index)))
			print("In: " + str(curve.get_point_in(index)))
			print("Out: " + str(curve.get_point_out(index)))
			curve.set_point_tilt(index, -curve.get_point_tilt(index)) 

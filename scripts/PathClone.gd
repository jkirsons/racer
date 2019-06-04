tool
extends Spatial
class_name PathClone

export var parent_path : NodePath
export var object_res : Resource

export var start_node : int
export var copies: int
export var space_between : float

export var offset : Vector3
export var rotate : bool
export var clamp_to_ground : bool
export var height_limit : float

# Called when the node enters the scene tree for the first time.
func _ready():
	var parent : Path = get_node(parent_path)
	parent.connect("curve_changed", self, "_on_Path_curve_changed")

func _on_Path_curve_changed():
	update_curve()
	
func update_curve():
	
	pass

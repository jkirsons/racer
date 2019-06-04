extends Camera

export (NodePath) var target_object = null
export var target_distance = 3.0
export var target_height = 2.0
export var move_speed = 20.0

var target_node = null
var last_lookat

func _ready():
	target_node = get_node(target_object)
	last_lookat = target_node.global_transform.origin
	

func _physics_process(delta):
	var target_pos = global_transform.origin	
	var target_vector = global_transform.origin - target_node.global_transform.origin
	
	# ignore y
	target_vector.y = 0.0
	
	if (target_vector.length() > target_distance):
		# limit vector to targe_distance
		target_vector = target_vector.normalized() * target_distance
		target_vector.y = target_height
		# set target pos to target_distance behind target
		target_pos = target_node.global_transform.origin + target_vector
	else:
		# only update height
		target_pos.y = target_node.global_transform.origin.y + target_height
	
	# interpolate to target pos
	global_transform.origin = global_transform.origin.linear_interpolate(target_pos, delta * move_speed)
	
	# interpolate look at to target
	last_lookat = last_lookat.linear_interpolate(target_node.global_transform.origin, delta * move_speed)
	look_at(last_lookat, Vector3.UP)
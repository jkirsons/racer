extends KinematicBody
# https://docs.godotengine.org/en/3.1/classes/class_kinematicbody.html
# https://docs.godotengine.org/en/3.1/tutorials/inputs/inputevent.html#what-is-it

var speed = 0.0
var steering = 0.0
export var acceleration = 20.0
export var friction_deceleration = 2.0
export var max_speed = 100.0
export var max_steering =  PI / 2 # radians
export var steering_speed = 1.0
export var hover_height = 0.8

export var gravity_acc = 10.0
export var hover_acc = 6

export var roll_speed = 4;
export var pitch_speed = 12;
export var yaw_speed = 8;

onready var aabb = get_node("CollisionShape/CSGBox").get_aabb()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta):
	process_input(delta)
	var ground_normal = get_gravity(delta)

	# apply steering
	global_transform.basis = global_transform.basis.rotated(global_transform.basis.y.normalized(), -steering * delta)
	
	# apply speed
	var velocity_vector = move_and_slide(global_transform.basis.xform(Vector3(0.0, 0.0, speed * -1)))
	
	# Project the normal onto a plane of the Y axis
	var p_z = Plane(global_transform.basis.z,0)
	var rot_vec_y = p_z.project(ground_normal.normalized())
	var z_rotation_angle = -global_transform.basis.y.angle_to(rot_vec_y) * sign(global_transform.basis.x.dot(rot_vec_y))
	global_transform.basis = global_transform.basis.orthonormalized().slerp( 
		global_transform.basis.rotated(global_transform.basis.z.normalized(), z_rotation_angle),
		delta * roll_speed)
		
	# Project forward vector onto ground normal plane
	var p_x = Plane(ground_normal.normalized(), 0)
	var rot_vec_z = p_x.project(global_transform.basis.z)
	var x_rotation_angle = -global_transform.basis.z.angle_to(rot_vec_z) * sign(global_transform.basis.y.dot(rot_vec_z))
	global_transform.basis = global_transform.basis.orthonormalized().slerp( 
		global_transform.basis.rotated(global_transform.basis.x.normalized(), x_rotation_angle),
		delta * pitch_speed)
		
	# if we have collided, then turn towards direction of collision
	#velocity_vector.y = 0
	var y_rotation_angle = 0
	if velocity_vector != Vector3.ZERO:
		var p_y = Plane(global_transform.basis.y,0)
		var rot_vec_x = p_y.project(-velocity_vector).normalized()
		y_rotation_angle = global_transform.basis.z.angle_to(rot_vec_x) * sign(global_transform.basis.x.dot(rot_vec_x))
		global_transform.basis = global_transform.basis.orthonormalized().slerp( 
			global_transform.basis.rotated(global_transform.basis.y.normalized(), y_rotation_angle),
			delta * yaw_speed)

func process_input(delta):
		# speed
	if Input.is_action_pressed("ui_up") && speed < max_speed :
		speed = speed + acceleration * delta
	elif Input.is_action_pressed("ui_down") && speed > 0.0:
		speed = speed - (acceleration * delta / 2)
	elif speed != 0:
		if(speed > 0):
			speed = speed - min(friction_deceleration * delta, speed)
		if(speed < 0):
			speed = speed + min(friction_deceleration * delta, speed*-1)
	
	# steering
	if Input.is_action_pressed("ui_left") && steering > -max_steering:
		steering -= steering_speed * delta
	elif Input.is_action_pressed("ui_right") && steering < max_steering:
		steering += steering_speed * delta
	elif steering != 0:
		if steering > 0:
			steering -= min(steering, steering_speed * delta*2)
		else:
			steering += min(steering * -1, steering_speed * delta*2)
	
func get_gravity(delta): 
	var height_offset = Vector3(0,0.1,0)
	var ray_points = Array()
	ray_points.push_back( global_transform.origin + aabb.position + height_offset)
	ray_points.push_back( global_transform.origin + aabb.position + aabb.size.x * Vector3(1,0,0) + height_offset)
	ray_points.push_back( global_transform.origin + aabb.position + aabb.size.z * Vector3(0,0,1) + height_offset)
	ray_points.push_back( global_transform.origin + aabb.position + aabb.size.x * Vector3(1,0,0) + aabb.size.z * Vector3(0,0,1) + height_offset)

	ray_points.push_back( global_transform.origin + aabb.position + aabb.size.x/2 * Vector3(1,0,0) + height_offset)
	ray_points.push_back( global_transform.origin + aabb.position + aabb.size.x/2 * Vector3(1,0,0) + aabb.size.z/2 * Vector3(0,0,1) + height_offset)
	ray_points.push_back( global_transform.origin + aabb.position + aabb.size.x/2 * Vector3(1,0,0) + aabb.size.z * Vector3(0,0,1) + height_offset)
		
	var space_state = get_world().direct_space_state
	
	# find average distance and normal
	var contact_points = 0
	var normal = Vector3.ZERO
	var distance = 0
	for point in ray_points:
		var to = point + global_transform.basis.y * -(hover_height + (gravity_acc-hover_acc) + height_offset.y )
		var coll = space_state.intersect_ray(point, to, [self])
		if coll:
			contact_points += 1
			distance += point.distance_to(coll.position) - height_offset.y 
			normal += coll.normal
	
	var grav_vector = Vector3.ZERO
	if !contact_points:
		grav_vector = Vector3(0, -gravity_acc , 0)
	else:
		normal /= contact_points
		distance /= contact_points
		grav_vector = Vector3(0, hover_acc * (hover_height  - distance), 0)
	
	move_and_slide(grav_vector)

	return normal
	#return global_transform.basis.get_rotation_quat().xform(grav_vector) 
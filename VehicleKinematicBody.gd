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
export var hover_height = 1

export var velocity_vector : Vector3
export var basis : Basis

onready var aabb = get_node("CollisionShape/CSGBox").get_aabb()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _physics_process(delta):
	move_and_slide(get_gravity(delta))
	
	process_input(delta)
	
	# apply steering
	global_transform.basis = global_transform.basis.rotated(global_transform.basis.y, -steering * delta)
	
	# apply steering
	var rot = global_transform.basis.get_rotation_quat()	
	velocity_vector = move_and_slide(rot.xform(Vector3(0.0, 0.0, speed * -1)))
	
	
	# if we have collided, then turn towards direction of collision
	velocity_vector.y = 0
	if velocity_vector.normalized() != Vector3.ZERO:
		global_transform.basis = Basis( velocity_vector.normalized().cross(Vector3.UP), Vector3.UP, velocity_vector.normalized())
		basis = global_transform.basis 
	

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
		# gravity
	var grav_vector = Vector3.ZERO
	var space_state = get_world().direct_space_state
	var from = global_transform.origin + aabb.position
	var to = global_transform.origin + aabb.position + global_transform.basis.y * -hover_height
	var coll = space_state.intersect_ray(from, to, [self])
	if !coll:
		grav_vector = Vector3(0, -10, 0)
	
	return grav_vector
	#return global_transform.basis.get_rotation_quat().xform(grav_vector) 
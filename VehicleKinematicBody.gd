extends KinematicBody
# https://docs.godotengine.org/en/3.1/classes/class_kinematicbody.html
# https://docs.godotengine.org/en/3.1/tutorials/inputs/inputevent.html#what-is-it

var speed = 0.0
var steering = 0.0
onready var aabb = get_node("CollisionShape/CSGBox").get_aabb()
export var acceleration = 200.0
export var friction_deceleration = 20.0
export var max_speed = 2000.0
export var max_steering =  PI / 2 # radians
export var steering_speed = 1.0
export var steering_vector = Vector3.ZERO


# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
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
			steering -= min(steering, steering_speed * delta)
		else:
			steering += min(steering * -1, steering_speed * delta)

	# apply speed/steering
	var rot = transform.basis.get_rotation_quat()
	transform.basis = transform.basis.rotated(transform.basis.y, -steering * delta)
	#steering_vector = Vector3(steering,0,0)
	move_and_slide(rot.xform(Vector3(0.0, 0.0, speed*delta*-1)) )
	
	
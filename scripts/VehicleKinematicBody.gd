#extends RigidDynamicBody3D
extends CharacterBody3D
class_name VehicleKinematicBody

var speed = 0.0
var steering = 0.0

@export_category("Vehicle")

@export_group("Speed")

## Engine Acceleration
@export var acceleration = 10.0 

## Maximum Vehicle Speed
@export var max_speed = 40.0

## Acceleration down, or in the direction of the track
@export var gravity_acc = 10.0

@export_group("Hover")

## Force pushing the vehicle back up off the track 
@export var hover_acc = 6.0

## Height to hover at
@export var hover_height = 0.6

@export_group("Deceleration")

## "Air Friction" that slows the vehicle down
@export var friction_deceleration = 5.0

## Decelleration when hitting an object 
@export var collision_speed_decrease = 10.0

@export_group("Roll Speed")

## Speed that the vehicle rolls to match the track
@export var roll_speed = 4.0;

## Speed that the vehicle pitches to match the track
@export var pitch_speed = 12.0;

## Speed that the vehicle yaws to match the track
@export var yaw_speed = 8.0;


@export_group("Steering")

## Maximum steering angle in radians
@export var max_steering : float =  PI / 3 # radians

## Speed to steer at
@export var steering_speed = 4.0

## Ship roll when steering
@export var steering_roll = 0.5

## Ship yaw when steering
@export var steering_yaw = 0.3

## Speed to return to center after steering
@export var steering_center_multiplier = 4 # multiplier when returning steering to center

@export_group("FX")

## Length of trails behind the vehicle
@export var max_trail_length = 4.5

@export_group("Debug")
@export var vehicle_gravity : Vector3
@export var vehicle_velocity : Vector3
@export var combined_velocity : Vector3
@export var ground_norm : Vector3
@export var global_transform_basis : Basis

@onready var aabb = get_node("CollisionShape3D/ship").get_aabb()
@onready var initial_pos = get_node("CollisionShape3D/ship").global_transform.origin
@onready var ship_model = get_node("CollisionShape3D")
@onready var static_collider = get_node("Static CollisionShape3D")
@onready var initial_basis = get_node("CollisionShape3D/ship").global_transform.basis

@onready var particles : CPUParticles3D = get_node("CPUParticles3D") as CPUParticles3D
#@onready var trail_left : Trail3D = get_node("CollisionShape/ship/Trail3D Left") as Trail3D
#@onready var trail_right : Trail3D = get_node("CollisionShape/ship/Trail3D Right") as Trail3D

var contact_points = 0

# Called when the node enters the scene tree for the first time.
#func _ready():
	#set_gravity_scale(0)

func _physics_process(delta):
	process_input(delta)
	
	#trail_left.length = (speed / max_speed) * max_trail_length
	#trail_right.length = (speed / max_speed) * max_trail_length
	#trail_left.segment_length = trail_left.length / trail_left.density_lengthwise
	#trail_right.segment_length = trail_right.length / trail_right.density_lengthwise
	var ret = get_vehicle_gravity(delta)
	var ground_normal = ret[0]
	var grav_vector = ret[1]

	# apply steering
	global_transform.basis = global_transform.basis.rotated(global_transform.basis.y.normalized(), -steering * delta)
	
	# apply speed
	var velocity_vector : Vector3 = Vector3.ZERO
	if speed != 0:
		self.velocity = global_transform.basis * Vector3(0.0, 0.0, speed * -1) + grav_vector
		
		# Debug
		vehicle_gravity = grav_vector
		vehicle_velocity = global_transform.basis * Vector3(0.0, 0.0, speed * -1)
		combined_velocity = self.velocity
		global_transform_basis = global_transform.basis
		ground_norm = ground_normal
		move_and_slide()

		# collision particles
		var collision_cnt = get_slide_collision_count()
		for i in range(0, collision_cnt):
			var collision = get_slide_collision(i)
			#var c = collision.get_collider_shape(0)
			if collision.get_collider_shape(0) != ship_model && collision.get_collider_shape(0) != static_collider:
				particles.global_transform.origin = collision.get_position(0)
		particles.emitting = is_on_wall()
		
	else:
		particles.emitting = false
		self.velocity = grav_vector
		move_and_slide()
	
	# Roll
	# Project the normal onto a plane of the Y axis
	# - Start with roll from normal of contact point, then add steering roll
	var p_z = Plane(global_transform.basis.z, 0.0)
	var rot_vec_y = p_z.project(ground_normal.normalized())
	var z_rotation_angle = -global_transform.basis.y.angle_to(rot_vec_y) * sign(global_transform.basis.x.dot(rot_vec_y))
	global_transform.basis = global_transform.basis.orthonormalized().slerp( 
		global_transform.basis.rotated(global_transform.basis.z.normalized(), z_rotation_angle),
		delta * roll_speed)
	
	# ship model - roll & yaw - adds a drifting effect
	var ship_speed_precent = speed / max_speed
	ship_model.transform.basis = ship_model.transform.basis.orthonormalized().slerp(
		initial_basis.rotated(initial_basis.z, -steering * steering_roll * ship_speed_precent).rotated(initial_basis.y,-steering * steering_yaw * ship_speed_precent),
		delta * roll_speed)
	
	# Yaw
	# - Project forward vector onto ground normal plane
	# - Adjust yaw towards this projection
	var p_x = Plane(ground_normal.normalized(), 0.0)
	var rot_vec_z = p_x.project(global_transform.basis.z)
	var x_rotation_angle = -global_transform.basis.z.angle_to(rot_vec_z) * sign(global_transform.basis.y.dot(rot_vec_z))
	global_transform.basis = global_transform.basis.orthonormalized().slerp( 
		global_transform.basis.rotated(global_transform.basis.x.normalized(), x_rotation_angle),
		delta * pitch_speed)
	
	# Pitch
	# - If we have collided, then turn towards direction of collision
	# velocity_vector.y = 0
	var y_rotation_angle = 0
	if velocity_vector != Vector3.ZERO:
		var p_y = Plane(global_transform.basis.y, 0.0)
		var rot_vec_x = p_y.project(-velocity_vector).normalized()
		y_rotation_angle = global_transform.basis.z.angle_to(rot_vec_x) * sign(global_transform.basis.x.dot(rot_vec_x))
		global_transform.basis = global_transform.basis.orthonormalized().slerp( 
			global_transform.basis.rotated(global_transform.basis.y.normalized(), y_rotation_angle),
			delta * yaw_speed)
		
		# If we have collided, then slow down 
		if speed > collision_speed_decrease and abs(y_rotation_angle) > 0.1:
			speed -= collision_speed_decrease * abs(y_rotation_angle)
			#print("Collision: " + str(collision_speed_decrease * abs(y_rotation_angle)))

func process_input(delta):
		# speed
	if Input.is_action_pressed("ui_up") && speed < max_speed :
		speed = speed + acceleration * delta
	elif Input.is_action_pressed("ui_down") && speed > 0.0:
		speed = speed - (acceleration * delta)
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
			steering -= min(steering, steering_speed * delta * steering_center_multiplier)
		else:
			steering += min(steering * -1, steering_speed * delta * steering_center_multiplier)
			
	# Restart
	if Input.is_action_pressed("ui_select"):
		self.transform.origin = Vector3(0.0, 0.0, 0.0)
		speed = 0
	
func get_vehicle_gravity(_delta): 
	var space_state = get_world_3d().direct_space_state
	var height_offset = Vector3(0.0, 0.1, 0.0) * global_transform.basis.y
	var aabb_y = Vector3(0.0, aabb.position.y, 0.0)
	var ray_points = [] #Array()
	
	# ray points down centre line
	ray_points.clear() # Godot 4 error - variable scope not respected
	ray_points.push_back( global_transform.origin + aabb_y * global_transform.basis.y  - (aabb.size.z/2) * global_transform.basis.z + height_offset)
	ray_points.push_back( global_transform.origin + aabb_y * global_transform.basis.y  + height_offset)
	ray_points.push_back( global_transform.origin + aabb_y * global_transform.basis.y  + (aabb.size.z/2) * global_transform.basis.z + height_offset)

	#ray_points.push_back( global_transform.origin + aabb_y * global_transform.basis.y  - (aabb.size.x/2) * global_transform.basis.x + height_offset)
	#ray_points.push_back( global_transform.origin + aabb_y * global_transform.basis.y  + (aabb.size.x/2) * global_transform.basis.x + height_offset)
	
	# find average distance and ground normal
	contact_points = 0
	var normal = Vector3.ZERO
	var distance = 999 #0
	for point in ray_points:
		var to = point + global_transform.basis.y * -(hover_height + (gravity_acc-hover_acc) + height_offset.y )
		var coll = space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point, to, 0xFFFFFFFF, [self]))
		if coll:
			contact_points += 1
			#distance += point.distance_to(coll['position']) - height_offset.y 
			distance = min(distance, point.distance_to(coll['position']) - height_offset.y)
			normal += coll['normal']
	
	var grav_vector = Vector3.ZERO
	if !contact_points:
		grav_vector = Vector3(0.0, -gravity_acc, 0.0)
		normal = Vector3.UP
	else:
		normal /= contact_points
		#distance /= contact_points
		grav_vector = Vector3(0.0, max(hover_acc * (hover_height  - distance), -gravity_acc), 0.0)

	return [normal,grav_vector]  # ground normal

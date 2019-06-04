extends RigidBody #KinematicBody

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _integrate_forces(state):
	if Input.is_action_pressed("ui_up"):
			#state.add_force( Vector3(0.0, 0.0, 0.1), Vector3.ZERO )
			state.set_linear_velocity(Vector3(0.0, 0.0, -1.0))
			print("Forward")
	
func _physics_process(delta):
	pass
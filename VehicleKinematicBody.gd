extends KinematicBody
# https://docs.godotengine.org/en/3.1/classes/class_kinematicbody.html
# https://docs.godotengine.org/en/3.1/tutorials/inputs/inputevent.html#what-is-it

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _physics_process(delta):
	if Input.is_action_pressed("ui_up"):
		move_and_slide(Vector3(0.0, 0.0, -1.0))
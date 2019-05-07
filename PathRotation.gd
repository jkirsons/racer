extends Path

export var points : PoolVector3Array
export var tilt : PoolRealArray
export var up : PoolVector3Array

# Called when the node enters the scene tree for the first time.
func _ready():
	print(curve.up_vector_enabled)
	points = curve.get_baked_points()
	tilt = curve.get_baked_tilts()
	up = curve.get_baked_up_vectors()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

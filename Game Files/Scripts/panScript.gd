extends MeshInstance2D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var speedX:Vector2 = Vector2(0.0,0)  
	var baseMovement:Vector2 = Vector2(0.005, 0)
	var move:Vector2 = speedX * baseMovement
	var currOffset = get_material().get_shader_parameter("offset")
	get_material().set_shader_parameter("offset", currOffset + move)
	pass

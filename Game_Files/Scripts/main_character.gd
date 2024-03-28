extends CharacterBody2D

# Put character's movement attributes in the inspector so they can be modified
@export var push_force  = 1000
@export var walk_speed  = 40.0
@export var diagonal_movement = false;
@export var facing : String = "NONE"
var tile_index : int
var tile_array 
# Function that runs on physics tick, rather than every frame.


var tilemap

func _ready():
	tile_array = $"../Tiles".tiles
	tilemap = $"../TileMap"  # Replace "TileMap" with the name of your TileMap node
	facing = "SOUTH"
func _physics_process(delta):
	if position:
		var tile_pos = tilemap.local_to_map(position)
		#var atlas_pos = tilemap.map_to_local(position)
		#print("Tile Position: ", tile_pos)
		var atlas_pos = tilemap.get_cell_atlas_coords(-1,tile_pos)
		print("Tile Atlas Position: ", atlas_pos)
		tile_index = atlas_pos.y * 6 + atlas_pos.x
		#print(index)
		print(tile_array[tile_index].desc, " facing ", facing)
		#print(facing)
		
		#print(tilemap.get_cell_atlas_coords(-1,tile_pos))
		# Process character movement input
		
		picture()
		movement_input()
		# Push a RigidBody2D node if we are colliding with one
		push()
		# Apply the calculated physics to our character for this tick
		move_and_slide()
# Picture Snapping code
func picture():
	var curr_tile = tile_array[tile_index]
	print("curr tile: ", curr_tile.exits)
	print("Curr tile & 1 = ", curr_tile.exits & 1)
	print("Curr tile & 2 = ", curr_tile.exits & 2)
	if (curr_tile.exits & 2 && curr_tile.exits & 1):
		if(facing == "WEST" || facing == "EAST"):
			print("Show Picture")
	if (curr_tile.exits & 8 && curr_tile.exits & 4):
		if(facing == "NORTH" || facing == "SOUTH"):
			print("Show Picture")
		
	
	pass
func push():
	# If we are moving
	if $".".move_and_slide():
		# For each point of collision
		for collisionIndex in $".".get_slide_collision_count():
			# Store the collision in a variable
			var collision = $".".get_slide_collision(collisionIndex)
			# If we are colliding with a RigidBody2D
			if collision.get_collider() is RigidBody2D:
				# Apply a force equal to our push_force attribute, located at the point of collision, in the opposite direction of that point's normal vector
				collision.get_collider().apply_force(collision.get_normal() * -push_force)

func movement_input():
	# Store the input from the arrow keys into a 2D vector, Ex: (+/-x, +/-y), (1,0) = left, (-1,0) = right, (0,1) = up, (0,-1) = down, (+/-0.70707..., +/-0.70707...) = diagonal, (0,0) = idle
	var direction = Input.get_vector("Move Left", "Move Right", "Move Up", "Move Down")
	#print(direction)
	# If we are not idle
	
	if(direction):
		# Apply velocity by multiplying the movement vector by a constant, our attribute, walk_speed
		
		if (abs(direction.x) == 1 or abs(direction.y) == 1) or diagonal_movement:
			velocity = direction * walk_speed
		#print(direction * walk_speed)
		# If we are moving in the x direction
		if (direction.x and !direction.y) or (diagonal_movement and direction.x):
			# Change to the horizontal sprite
			$AnimatedSprite2D.frame = 2
			# If we are moving left, flip the sprite horizontally
			if direction.x < 0:
				$AnimatedSprite2D.flip_h = true
				facing = "WEST"
			else:
				$AnimatedSprite2D.flip_h = false
				facing = "EAST"
		# If we are moving in the y direction
		if (direction.y and !direction.x) or (diagonal_movement and direction.y): 
			# If we are moving down, use the downward facing sprite, if we are moving up, use the upward facing sprite
			if direction.y < 0:
				$AnimatedSprite2D.frame = 1
				facing = "NORTH"
			else:
				$AnimatedSprite2D.frame = 0
				facing = "SOUTH"
	# If we are not moving, linearly interpolate (lerp/smoothly change) our velocity to zero so the stopping feels like decelerating rather than rigidly stopping
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.y = move_toward(velocity.y, 0, walk_speed)


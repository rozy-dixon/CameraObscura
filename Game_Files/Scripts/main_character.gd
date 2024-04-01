extends CharacterBody2D

# Put character's movement attributes in the inspector so they can be modified
@export var push_force  = 1000
@export var walk_speed  = 40.0
@export var diagonal_movement = false;
@export var jumpy_movement = true;
enum DIR{NORTH, SOUTH, WEST, EAST}
@export var facing : int = DIR.SOUTH

# The boundaries of the screen, in the bounds of the tileset.
const MAX_X : int = 300
const MAX_Y : int = 270
const MIN_X : int = 20
const MIN_Y : int = 18

# The tilemap in the main scene
var tilemap
# Array of Tile Objects that have exit properties
var tile_array 

# The position on the screen in terms of Tiles
var tile_pos
# The position on the screen in world coordinates
var world_pos
# The location of the tile we are standing on in the tilemap
var atlas_pos
# The index in the tile_array that corresponds to the tile we are standing on
var tile_index : int
# The Tile object we are standing on
var tile_obj


# Keep track of what defines a Tile that is not actually placed
var unknown_tile = Vector2i(-1,-1)


# Takes in atlas coords, returns tile object.
func atlas_to_arr(destination_tile):
	print(destination_tile)
	var t = destination_tile.y * 6 + destination_tile.x
	var dest_tile_obj = tile_array[t]
	return dest_tile_obj
	
	
func _ready():
	tile_array = $"../Tiles".tiles
	tilemap = $"../TileMap"  # Replace "TileMap" with the name of your TileMap node
	facing = DIR.SOUTH
	position = tilemap.map_to_local(Vector2(0,0))

func _physics_process(delta):
	if position:
		tile_pos = tilemap.local_to_map(position)
		world_pos = tilemap.map_to_local(tile_pos)
		atlas_pos = tilemap.get_cell_atlas_coords(-1,tile_pos)
		tile_index = atlas_pos.y * 6 + atlas_pos.x
		#print(tile_array[tile_index].desc, " facing ", facing)
		
		#print(tilemap.get_cell_atlas_coords(-1,tile_pos))
		# Process character movement input
		if(Input.is_action_just_pressed("Take Picture")) && $"../Photo".visible == false:
			picture()
		elif Input.is_action_just_pressed("Take Picture") && $"../Photo".visible == true:
			$"../Photo".visible = false
		if(!jumpy_movement):
			movement_input()
			# Push a RigidBody2D node if we are colliding with one
			push()
			# Apply the calculated physics to our character for this tick
			move_and_slide()
		else:
			hop()
			look()

# Sets sprite and facing variable based on where the character is looking
func look():
	if(Input.is_action_just_pressed("Look Left")):
		facing = DIR.WEST
		$AnimatedSprite2D.frame = 2
		$AnimatedSprite2D.flip_h = true
	if(Input.is_action_just_pressed("Look Right")):
		facing = DIR.EAST
		$AnimatedSprite2D.frame = 2
		$AnimatedSprite2D.flip_h = false
	if(Input.is_action_just_pressed("Look Up")):
		facing = DIR.NORTH
		$AnimatedSprite2D.frame = 1
	if(Input.is_action_just_pressed("Look Down")):
		facing = DIR.SOUTH
		$AnimatedSprite2D.frame = 0

# Hopping movement code
func hop():
		tile_pos = tilemap.local_to_map(position)
		world_pos = tilemap.map_to_local(tile_pos)
		atlas_pos = tilemap.get_cell_atlas_coords(-1,tile_pos)
		var destination_tile
		var possible_jump : bool = true;
		if Input.is_action_just_pressed("Move Left") && world_pos.x > MIN_X:
			destination_tile = tilemap.get_cell_atlas_coords(-1, tile_pos + Vector2i(-1,0))
			possible_jump = destination_tile != unknown_tile
			var curr = atlas_to_arr(destination_tile)
			if curr.exits & 0b0001 && possible_jump:
				position = tilemap.map_to_local(tile_pos + Vector2i(-1,0))

		elif Input.is_action_just_pressed("Move Right") && world_pos.x < MAX_X:
			destination_tile = tilemap.get_cell_atlas_coords(-1, tile_pos + Vector2i(1,0))
			possible_jump = destination_tile != unknown_tile
			var curr = atlas_to_arr(destination_tile)
			if curr.exits & 0b0010 && possible_jump:
				position = tilemap.map_to_local(tile_pos + Vector2i(1,0))

			
		if Input.is_action_just_pressed("Move Up") && world_pos.y > MIN_Y:
			destination_tile = tilemap.get_cell_atlas_coords(-1, tile_pos + Vector2i(0,-1))
			possible_jump = destination_tile != unknown_tile
			var curr = atlas_to_arr(destination_tile)
			if curr.exits & 0b0100 && possible_jump:
				position = tilemap.map_to_local(tile_pos + Vector2i(0,-1))


		elif Input.is_action_just_pressed("Move Down") && world_pos.y < MAX_Y:
			destination_tile = tilemap.get_cell_atlas_coords(-1, tile_pos + Vector2i(0,1))
			possible_jump = destination_tile != unknown_tile
			var curr = atlas_to_arr(destination_tile)
			if curr.exits & 0b1000 && possible_jump:
				position = tilemap.map_to_local(tile_pos + Vector2i(0,1))

# Picture Snapping code
func picture():
	tile_pos = tilemap.local_to_map(position)
	tile_obj = tile_array[tile_index]
	
	var destination_tile : T
	destination_tile.atlasCoords = tile_obj.atlasCoords
	match facing:
		DIR.NORTH:
			destination_tile.atlasCoords += Vector2i(0,-1)
		DIR.SOUTH:
			destination_tile.atlasCoords += Vector2i(0,1)
		DIR.WEST:
			destination_tile.atlasCoords += Vector2i(-1,0)
		DIR.EAST:
			destination_tile.atlasCoords += Vector2i(1,0)
	# Create random number for exits
	# Or the correct bit
	# Grab adjacent tiles
	# Are we on a boundary?
	# Will this mess up a connection between existing tiles?
	
	##print("curr tile: ", tile_obj.exits)
	##print("FACING: ", facing)
	##print("Curr tile & 1 = ", tile_obj.exits & 1)
	##print("Curr tile & 2 = ", tile_obj.exits & 2)
	##print("Curr tile & 4 = ", tile_obj.exits & 4)
	##print("Curr tile & 8 = ", tile_obj.exits & 8)
	##if (tile_obj.exits & 2 && facing == "WEST" || tile_obj.exits & 1 && facing == "EAST"):
		##$"../Photo".visible = true
		####print("Show Picture")
	##if (tile_obj.exits & 8 && facing == "NORTH" || tile_obj.exits & 4 && facing == "SOUTH"):
		##$"../Photo".visible = true
		####print("Show Picture")
	#var destination_tile : Vector2i
	#if facing == "NORTH":
		#destination_tile = tilemap.get_cell_atlas_coords(-1, tile_pos + Vector2i(0,-1))
		#var world_pos = tilemap.map_to_local(destination_tile)
		#if world_pos.y > -18 && destination_tile == unknown_tile:
			#$"../Photo".visible = true
		#pass
	#if facing == "SOUTH":
		#destination_tile = tilemap.get_cell_atlas_coords(-1, tile_pos + Vector2i(0,1))
		#var world_pos = tilemap.map_to_local(destination_tile)
		#print(world_pos.y)
		#print(destination_tile == unknown_tile)
		#if world_pos.y >= -18 && destination_tile == unknown_tile:
			#$"../Photo".visible = true
		#pass
	#if facing == "EAST":
		#destination_tile = tilemap.get_cell_atlas_coords(-1, tile_pos + Vector2i(1,0))
		#var world_pos = tilemap.map_to_local(destination_tile)
		#if world_pos.y > -18 && destination_tile == unknown_tile:
			#$"../Photo".visible = true
		#pass
	#if facing == "WEST":
		#destination_tile = tilemap.get_cell_atlas_coords(-1, tile_pos + Vector2i(-1,0))
		#var world_pos = tilemap.map_to_local(destination_tile)
		#if world_pos.y > -18 && destination_tile == unknown_tile:
			#$"../Photo".visible = true
		#pass

# Physics code if we want to push objects.
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

# Free movement code, uses physics engine
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
				facing = DIR.WEST
			else:
				$AnimatedSprite2D.flip_h = false
				facing = DIR.EAST
		# If we are moving in the y direction
		if (direction.y and !direction.x) or (diagonal_movement and direction.y): 
			# If we are moving down, use the downward facing sprite, if we are moving up, use the upward facing sprite
			if direction.y < 0:
				$AnimatedSprite2D.frame = 1
				facing = DIR.NORTH
			else:
				$AnimatedSprite2D.frame = 0
				facing = DIR.SOUTH
	# If we are not moving, linearly interpolate (lerp/smoothly change) our velocity to zero so the stopping feels like decelerating rather than rigidly stopping
	else:
		velocity.x = move_toward(velocity.x, 0, walk_speed)
		velocity.y = move_toward(velocity.y, 0, walk_speed)


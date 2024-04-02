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
var tilemap : TileMap
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

# Convert integer to binary string
func to_binary(num):
	var retval = ""
	var digit : String
	#print("Converting ", num, " to binary")
	while num:
		digit = str(num % 2)
		num /= 2
		# Prepend
		retval = digit + retval
	# Pad if needed
	while retval.length() < 4:
		retval = "0" + retval
	#print("Result is: ", retval)
	return retval

# Takes in atlas coords, returns tile object.
func atlas_to_arr(destination_tile):
	#print(destination_tile)
	var t = destination_tile.y * 6 + destination_tile.x
	var dest_tile_obj = tile_array[t]
	return dest_tile_obj
	
	#use Vector2i.(xxx) for direction
func set_tile(tile_pos, atlas_pos, direction):
	var tile_map_layer = -1 
	var tile_data = tilemap.get_cell_tile_data(tile_map_layer, tile_pos)
	if !tile_data: 
		var tile_map_cell_source_id = tilemap.get_cell_source_id(tile_map_layer, tile_pos); 
		var tile_map_cell_atlas_coords = tilemap.get_cell_atlas_coords(tile_map_layer, tile_pos) 
		var tile_map_cell_alternative = tilemap.get_cell_alternative_tile(tile_map_layer, tile_pos) 
		var new_tile_map_cell_position =tile_pos + Vector2i.RIGHT 
		tilemap.set_cell(tile_map_layer, new_tile_map_cell_position, tile_map_cell_source_id, atlas_pos, tile_map_cell_alternative)

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
	
	# dest_tile = tile position on the game screen
	var dest_tile : Vector2i
	dest_tile = tile_pos
	match facing:
		DIR.NORTH:
			dest_tile += Vector2i(0,-1)
		DIR.SOUTH:
			dest_tile += Vector2i(0,1)
		DIR.WEST:
			dest_tile += Vector2i(-1,0)
		DIR.EAST:
			dest_tile += Vector2i(1,0)
	# Has this tile already been generated?
	# dest_atlas = atlas coordinates of the destination
	var dest_atlas = tilemap.get_cell_atlas_coords(-1,dest_tile) 
	if(dest_atlas != unknown_tile):
		return
	# Is this tile outside of the boundaries of the map?
	if(dest_tile.x < 0 or dest_tile.y < 0 or dest_tile.x > 7 or dest_tile.y > 7):
		return
	
	# Are we facing an open exit?
	match facing:
		DIR.NORTH:
			if(tile_obj.exits & 0b1000 == 0):
				return
		DIR.SOUTH:
			if(tile_obj.exits & 0b0100 == 0):
				return
		DIR.WEST:
			if(tile_obj.exits & 0b0010 == 0):
				return
		DIR.EAST:
			if(tile_obj.exits & 0b0001 == 0):
				return
	
	# Create random number for exits
	# dest_exits is the exits to be generated for the destination tile
	var dest_exits = randi_range(0,15)
	# bin_exits = binary representation of the exit configuration of the destination
	var bin_exits = to_binary(dest_exits)
	#print("Before conversion: ", bin_exits) 
	
	# Bitwise OR the correct bit
	match facing:
		DIR.NORTH:
			# Facing North, we want something with a Southern exit.
			dest_exits |= 0b0100
		DIR.SOUTH:
			# Facing South, we want something with a Northern exit.
			dest_exits |= 0b1000
		DIR.WEST:
			# Facing West, we want something with a Eastern exit.
			dest_exits |= 0b0001
		DIR.EAST:
			# Facing East, we want something with a Western exit.
			dest_exits |= 0b0010
	bin_exits = to_binary(dest_exits)
	#print("After Conversion: ", bin_exits) 
	
	# Grab adjacent tiles
	# Creating an array of the 8 tiles tile_pos's that surround the destination, we will end up grabbing the tile we are standing on, but that shouldn't
		# be a problem
	var adj = []
	
	# Top Left
	var tl = dest_tile + Vector2i(-1,-1)
	adj.append(tl)
	
	# Top
	var t = dest_tile + Vector2i(0,-1)
	adj.append(t)
	
	# Top Right
	var tr = dest_tile + Vector2i(1,-1)
	adj.append(tr)
	
	# Middle Left
	var ml = dest_tile + Vector2i(-1,0)
	adj.append(ml)
	
	# Middle Right
	var mr = dest_tile + Vector2i(1,0)
	adj.append(mr)
	
	# Bottom Left
	var bl = dest_tile + Vector2i(-1,1)
	adj.append(bl)
	
	# Bottom
	var b = dest_tile + Vector2i(0,1)
	adj.append(b)
	
	# Bottom Right
	var br = dest_tile + Vector2i(1,1)
	adj.append(br)
	
	# Are we on a boundary?
	for tile in adj:
		if tile.x < 0:
			# We need to block the exit in the destination at the West side
			dest_exits &= 0b1101
		if tile.x > 7:
			# Block East side
			dest_exits &= 0b1110
		if tile.y < 0:
			# Block North
			dest_exits &= 0b0111
		if tile.y > 7:
			# Block South
			dest_exits &= 0b1011
	
	# Grab atlas coords for tile
	
	# Use set_tile function I wrote to place tile
	
	# Will this mess up a connection between existing tiles?
	# Could call this recursively to parse surrounding tiles until none of the tiles OR'ed have to change at all.
	
	# Show Picture
	
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


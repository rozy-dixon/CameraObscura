extends CharacterBody2D

# Put character's movement attributes in the inspector so they can be modified
@export var push_force  = 1000
@export var walk_speed  = 40.0
@export var diagonal_movement = false;
@export var jumpy_movement = true;

# Handles direction of character
enum DIR{NORTH = 8, SOUTH = 4, WEST = 2, EAST = 1}
@export var facing : int = DIR.SOUTH

# The boundaries of the screen, in the bounds of the tileset.
const MAX_X : int = 300
const MAX_Y : int = 270
const MIN_X : int = 20
const MIN_Y : int = 18

# Size of the rows in our tileset, used to index the array because it is converting 2D to 1D
const ROW_SIZE : int = 6

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

# The amount of range our camera can go
var pic_dist : int = 2

# Given an atlas coord, find what index it is in the array
func atlas_to_index(atlas):
	# Apply a conversion of the components of the atlas Vector2i to return an integer of it's corresponding tile in the array
	var row = atlas.y
	var col = atlas.x
	var index = row * ROW_SIZE + col
	return index

# Convert integer to binary string
func to_binary(num):
	var retval = ""
	var digit : String
	while num:
		digit = str(num % 2)
		num /= 2
		# Prepend
		retval = digit + retval
	# Pad if needed
	while retval.length() < 4:
		retval = "0" + retval
	return retval

# Takes in atlas coords, returns tile object.
func atlas_to_arr(destination_tile):
	
	var dest_tile_obj = tile_array[atlas_to_index(destination_tile)]
	return dest_tile_obj


# Function places a tile, using tile_pos as the origin
#use Vector2i.(xxx) for direction
func set_tile(tile_pos, atlas_pos, direction):
	# Layer is at 0
	var tilemap_layer = 0
	# Checking to see if it is an empty space, going to change this for "place_tile()"
	var tile_data = tilemap.get_cell_tile_data(tilemap_layer, tile_pos)
	# If there is an empty space
	if !tile_data: 
		# These default to 0 as well
		var tilemap_cell_source_id = 0
		var tilemap_cell_alternative = 0
		tilemap.set_cell(tilemap_layer, tile_pos, tilemap_cell_source_id, atlas_pos, tilemap_cell_alternative)

func _ready():
	# Pull the objects from the class into variables in this script
	tile_array = $"../Tiles".tiles
	tilemap = $"../TileMap" 
	# Start facing south
	facing = DIR.SOUTH
	# Start at the origin
	position = tilemap.map_to_local(Vector2(0,0))

func _physics_process(delta):
	if position:
		# Grab and set our tile coords, world coords, atlas coords, index in the array, and what tile in the array that we are standing on
		tile_pos = tilemap.local_to_map(position)
		world_pos = tilemap.map_to_local(tile_pos)
		atlas_pos = tilemap.get_cell_atlas_coords(-1,tile_pos)
		tile_index = atlas_pos.y * ROW_SIZE + atlas_pos.x
		tile_obj = tile_array[tile_index]

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
func look(option = -1):
	if(Input.is_action_just_pressed("Look Left") || option == DIR.WEST):
		facing = DIR.WEST
		$AnimatedSprite2D.frame = 2
		$AnimatedSprite2D.flip_h = true
	if(Input.is_action_just_pressed("Look Right") || option == DIR.EAST):
		facing = DIR.EAST
		$AnimatedSprite2D.frame = 2
		$AnimatedSprite2D.flip_h = false
	if(Input.is_action_just_pressed("Look Up") || option == DIR.NORTH):
		facing = DIR.NORTH
		$AnimatedSprite2D.frame = 1
	if(Input.is_action_just_pressed("Look Down") || option == DIR.SOUTH):
		facing = DIR.SOUTH
		$AnimatedSprite2D.frame = 0

# Hopping movement code
func hop():
		var destination_tile
		var possible_jump : bool = true;
		
		if Input.is_action_just_pressed("Move Left"):
			look(DIR.WEST)
			if world_pos.x > MIN_X:
				destination_tile = tilemap.get_cell_atlas_coords(-1, tile_pos + Vector2i(-1,0))
				possible_jump = destination_tile != unknown_tile
				var curr = atlas_to_arr(destination_tile)
				if curr.exits & 0b0001 && possible_jump:
					position = tilemap.map_to_local(tile_pos + Vector2i(-1,0))
		
		elif Input.is_action_just_pressed("Move Right"):
			look(DIR.EAST)
			if world_pos.x < MAX_X:
				destination_tile = tilemap.get_cell_atlas_coords(-1, tile_pos + Vector2i(1,0))
				possible_jump = destination_tile != unknown_tile
				var curr = atlas_to_arr(destination_tile)
				if curr.exits & 0b0010 && possible_jump:
					position = tilemap.map_to_local(tile_pos + Vector2i(1,0))
			
		elif Input.is_action_just_pressed("Move Up"):
			look(DIR.NORTH)
			if world_pos.y > MIN_Y:
				destination_tile = tilemap.get_cell_atlas_coords(-1, tile_pos + Vector2i(0,-1))
				possible_jump = destination_tile != unknown_tile
				var curr = atlas_to_arr(destination_tile)
				if curr.exits & 0b0100 && possible_jump:
					position = tilemap.map_to_local(tile_pos + Vector2i(0,-1))

		elif Input.is_action_just_pressed("Move Down"):
			look(DIR.SOUTH)
			if world_pos.y < MAX_Y:
				destination_tile = tilemap.get_cell_atlas_coords(-1, tile_pos + Vector2i(0,1))
				possible_jump = destination_tile != unknown_tile
				var curr = atlas_to_arr(destination_tile)
				if curr.exits & 0b1000 && possible_jump:
					position = tilemap.map_to_local(tile_pos + Vector2i(0,1))

				
# Picture Snapping code
func picture(tile_pos = tile_pos, facing = facing, pic_dist = 2):
	# Create a variable for the tile coords of the tile we are going to generate
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
	# TODO: Change these to consts
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
	# After thinking about it, I don't think diagonal tiles matter.
	# I also think that grabbing the origin tile in this can lead to checking tiles that have already been checked which is inefficient.
	# That being said, I am going to exclude tiles we do not need and recursively call a fixing method on them... eventually if needed.
	
	
	# Will this mess up a connection between existing tiles?
	# Should we care? Or is it interesting to the gameplay?
	# Could call this recursively to parse surrounding tiles until none of the tiles OR'ed have to change at all.
	
	var adj = []
	
	# Top Left
	#var tl = dest_tile + Vector2i(-1,-1)
	#adj.append(tl)
	
	# North
	# Grab tile's position
	var n = dest_tile + Vector2i(0,-1)
	adj.append(n)
	# Figure out what kind of tile it is
	var n_atlas = tilemap.get_cell_atlas_coords(-1,n)
	# Get its index in the array
	var n_index = atlas_to_index(n_atlas)
	# Figure out it's exit configuration
	print("n_index ", n_index)
	if n_index && n_index > 0 && n_index < 16:
		var n_exits = tile_array[n_index].exits
		# Block or open the necessary channel
		# If the tile north of us has a southern opening, we need a northern opening
		# n ?= 0bx1xx? -> curr = 0bx1xx
		if n_exits & 0b0100:
			print("tile to the north of the destination has a southern opening")
			# OR'ing the exit sets the bit
			print("EXITS BEFORE ", dest_exits)
			dest_exits |= 0b1000
			print("EXITS AFTER ", dest_exits) #0100
		else:
			print("tile to the north of the destination has a southern wall")
			print("EXITS BEFORE ", dest_exits) #0100
			dest_exits &= 0b0111               #0111
			print("EXITS AFTER ", dest_exits) #0100
		
	# West
	var w = dest_tile + Vector2i(-1,0)
	adj.append(w)
	var w_atlas = tilemap.get_cell_atlas_coords(-1,w)
	# Get its index in the array
	var w_index = atlas_to_index(w_atlas)
	# Figure out it's exit configuration
	print("w_index ", w_index)
	if w_index && w_index > 0 && w_index < 16:
		var w_exits = tile_array[w_index].exits
		# Block or open the necessary channel
		# If the tile west of us has a eastern opening, we need a western opening
		# n ?= 0bxx1x? -> curr = 0bxx1x
		if w_exits & 0b0001:
			print("tile to the west of the destination has an eastern opening")
			# OR'ing the exit sets the bit
			print("EXITS BEFORE ", dest_exits)
			dest_exits |= 0b0010
			print("EXITS AFTER ", dest_exits) #0100
		else:
			print("tile to the west of the destination has an eastern wall")
			# CREATE a western wall
			print("EXITS BEFORE ", dest_exits)
			dest_exits &= 0b1101
			print("EXITS AFTER ", dest_exits)
	# East
	var e = dest_tile + Vector2i(1,0)
	adj.append(e)
	var e_atlas = tilemap.get_cell_atlas_coords(-1,e)
	# Get its index in the array
	var e_index = atlas_to_index(e_atlas)
	# Figure out it's exit configuration
	print("e_index ", e_index)
	if e_index && e_index > 0 && e_index < 16:
		var e_exits = tile_array[e_index].exits
		# Block or open the necessary channel
		# If the tile east of us has a western opening, we need a eastern opening
		# n ?= 0bxxx1? -> curr = 0bxxx1
		if e_exits & 0b0010:
			print("tile to the east of the destination has a western opening")
			# OR'ing the exit sets the bit
			print("EXITS BEFORE ", dest_exits)
			dest_exits |= 0b0001
			print("EXITS AFTER ", dest_exits) #0100
		else:
			print("tile to the east of the destination has a western wall")
			print("EXITS BEFORE ", dest_exits)
			dest_exits &= 0b1110
			print("EXITS AFTER ", dest_exits)

		
	# South
	var s = dest_tile + Vector2i(0,1)
	adj.append(s)
	var s_atlas = tilemap.get_cell_atlas_coords(-1,s)
	# Get its index in the array
	var s_index = atlas_to_index(s_atlas)
	# Figure out it's exit configuration
	print("s_index ", s_index)
	#print(s_index)
	if s_index && s_index > 0 && s_index < 16:
		var s_exits = tile_array[s_index].exits
		# Block or open the necessary channel
		# If the tile south of us has a northern opening, we need a southern opening
		# n ?= 0bx1xx? -> curr = 0bx1xx
		if s_exits & 0b1000:
			print("tile to the south of the destination has a northern opening")
			# OR'ing the exit sets the bit
			print("EXITS BEFORE ", dest_exits)
			dest_exits |= 0b0100
			print("EXITS AFTER ", dest_exits) #0100
		else:
			print("tile to the south of the destination has a northern wall")
			print("EXITS BEFORE ", dest_exits)
			dest_exits &= 0b1011
			print("EXITS AFTER ", dest_exits)
	
	print("exit config after neighbor filter ", dest_exits)
	print("")
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
		# Atlas coords are found in the tile_obj that is at tile_array[dest.exits]
	dest_atlas = tile_array[dest_exits].atlas_coords
	
	# Use set_tile function I wrote to place tile
	#print("Placing tile ", tile_array[dest_exits].desc)
	set_tile(dest_tile,dest_atlas,facing)
	print ("pic_dist = ", pic_dist)
	# If there is an opening, keep placing tiles
	if(pic_dist != 0):
		match facing:
			DIR.NORTH:
				# if we are facing north and just generated a tile with a northern entrance, generate again
				if dest_exits & 0b1000:
					picture(dest_tile, facing, pic_dist - 1)
			DIR.SOUTH:
				if dest_exits & 0b0100:
					picture(dest_tile, facing, pic_dist - 1)
			DIR.WEST:
				if dest_exits & 0b0010:
					picture(dest_tile, facing, pic_dist - 1)
			DIR.EAST:
				if dest_exits & 0b0001:
					picture(dest_tile, facing, pic_dist - 1)
					
	else:
		pic_dist = 2
	# Show Picture
	# Decide the proper picture to show based on the direction facing and the PLACED tile. We would want to be looking at the unique configuration of the 
		# tile we generated, not the entrance we are standing in leading to it, that wouldn't mesh with the feeling at all.
	# This is going to attempt to show the picture multiple times
		
	
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


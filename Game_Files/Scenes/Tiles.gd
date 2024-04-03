extends Node

class_name T
var atlas_coords : Vector2i
var exits : int
var desc : String
# I'll change this if the zero offset makes this confusing.
const TILE_MAX : int = 16

#var tile = preload("res://Scenes/Tile.tscn")
# Every tile's index in the array, is also its exits.
@export var tiles = []
# Called when the node enters the scene tree for the first time.
func _ready():
	var exits = 0
	for i in range(3):
		for j in range(6):
				var curr = T.new()
				curr.atlas_coords.x = j
				curr.atlas_coords.y = i
				curr.exits = exits
				# Binary number corresponds to top, bottom, left, right exits
				match curr.exits:
					0b0000:
						curr.desc = "Fully Blocked Tile"
					0b0001:
						curr.desc = "Left Dead-End"
					0b0010:
						curr.desc = "Right Dead-End"
					0b0011:
						curr.desc = "Horizontal Hallway"
					0b0100:
						curr.desc = "Top Dead-End"
					0b0101:
						curr.desc = "Top-Left Corner"
					0b0110:
						curr.desc = "Top-Right Corner"
					0b0111:
						curr.desc = "T-Shape Tile"
					0b1000:
						curr.desc = "Bottom Dead-End"
					0b1001:
						curr.desc = "Bottom-Left Corner"
					0b1010:
						curr.desc = "Bottom-Right Corner"
					0b1011:
						curr.desc = "Upside-Down T Tile"
					0b1100:
						curr.desc = "Vertical Hallway"
					0b1101:
						curr.desc = "Right-Facing T"
					0b1110:
						curr.desc = "Left-Facing T"
					0b1111:
						curr.desc = "Cross Tile"
				exits+=1
				#print("Made tile ", curr.desc, " at atlas coords ", curr.atlas_coords)
				tiles.append(curr)
				#$".".add_child(curr)
pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print(tiles.size())
	pass

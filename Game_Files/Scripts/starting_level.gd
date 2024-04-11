extends Node2D
### PRELOADED SCENES ###
var pocket_item_ui = preload("res://Scenes/pocket_item.tscn")
var pocket_space : int

var pocket_display 

var inventory 

# Called when the node enters the scene tree for the first time.
func _ready():
	pocket_display = $UI/HBoxContainer
	pocket_space = 0
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#print("pocket space: ", pocket_space, "\ninventory size: ", $"main character".inventory.size())
	inventory = $"main character".inventory
	if(pocket_space < inventory.size()):
		# Instantiate scene
		if pocket_item_ui:
			var item = pocket_item_ui.instantiate()
			if !item:
				print("intantiate fail")
			else:
				print("Adding child")
				var item_children = item.get_children(true);
				
				item_children[0].frame = inventory.back();
				$UI/HBoxContainer.add_child(item)
				pocket_space = inventory.size()
		else:
			print("preload fail")
	if(pocket_space > inventory.size()):
		# Remove child
		var items = $UI/HBoxContainer.get_children()
		var remove = items[inventory.size()]
		$UI/HBoxContainer.remove_child(remove)
		pocket_space = inventory.size()
	#print($Tiles.tiles)
	pass

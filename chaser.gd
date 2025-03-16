extends CharacterBody3D

# How fast the player moves in meters per second.
@export var speed = 2
# Declare the variable to hold the player reference
var player
func _ready():
	# Assume the player is named "Player" in the scene
	player = get_parent().get_node("Player")
	# Ensure the player node exists
	if not player:
		print("Player node not found!")
		return
	

func _physics_process(_delta):
	# Get the vector to the player
	var direction_to_player = (player.global_position - global_position)
	print(direction_to_player)
	# Update the velocity
	velocity = direction_to_player * speed
	move_and_slide()

extends Node3D

@export var player_scene: PackedScene
@export var bulldog_scene: PackedScene

@onready var Bulldog = preload("res://bulldog.gd")  # Adjust the path

const NUMBER_OF_PLAYERS = 7

var runners_center_spawn_position = Vector3(0, 0.5, 20)
var chasers_center_spawn_position = Vector3(0, 0.5, -22)
#var player
#@onready players_container = $Players  # Node to hold player and AI instances
var runners = []
var chasers = []

func get_runners():
	return runners

func get_chasers():
	return chasers
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Spawn the user-controlled player
	game_start()
	
# Function to initialize player and bulldogs
# Game start is 1 chaser bulldog, 5 runner bulldogs and one runner (player-controlled)
func game_start() -> void:

	# Add player and 5 runner bulldogs
	var player = player_scene.instantiate()  # Create an instance of the PlayerCharacter
	add_child(player) 
	runners.append(player)
	
	for n in 5:
		var runner_bulldog = bulldog_scene.instantiate()
		runner_bulldog.set_state(Bulldog.RUN)
		runners.append(runner_bulldog)
		print(runners)
		add_child(runner_bulldog)
	
	#add 1 chaser bulldog at start of game
	var chaser_bulldog = bulldog_scene.instantiate()
	chaser_bulldog.set_state(Bulldog.CHASE)
	chasers.append(chaser_bulldog)
	add_child(chaser_bulldog) 
	print(chasers)
	
	round_start(runners,chasers)
	
	
# starts a round of bulldog takes array of chasers and runners and spawns them
func round_start(round_start_runners, round_start_chasers) -> void:
	position_runners(round_start_runners)
	position_chasers(round_start_chasers)
	
# Position chasers in a grouping in the centre of the play area # 1-6 possible shapes
func position_chasers(starting_chasers) -> void:
	
	starting_chasers.shuffle()
	#place at center
	for bulldog in starting_chasers:
		bulldog.global_position = chasers_center_spawn_position
		print("Chaser %s placed at %s" % [bulldog, bulldog.global_position])

# Position runners in a line in the start area
func position_runners(starting_runners) -> void:
	print("Positioning %d runners" % [starting_runners.size()])
	starting_runners.shuffle()
	var positions = []
	var spacing = 3
	var start = runners_center_spawn_position
	#gen start position
	start.x = runners_center_spawn_position.x - (starting_runners.size() - 1) * spacing / 2
	
	for bulldog in starting_runners.size():
		positions.append(start.x + bulldog * spacing)
		
	# Update the global positions of each runner
	for i in range(starting_runners.size()):
		var runner = starting_runners[i]
		var new_position = Vector3(positions[i], 0, 22) # Preserve Y position
		runner.global_position = new_position
		print("Runner %d placed at %s" % [i, new_position])

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#if player:
	#	print("Player position:", player.global_position)
	#else:
	#	print("Player has not been spawned yet.")
	
	

	

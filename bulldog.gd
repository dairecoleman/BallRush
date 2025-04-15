extends CharacterBody3D

@onready var navigation_agent_3d: NavigationAgent3D = get_node_or_null("NavigationAgent3D")
@export var flee_radius: float = 10.0  # Radius within which to react to chasers
@export var flee_weight: float = 0.4  # 0 = only goal, 1 = only fleeing
# How fast the player moves in meters per second.
@export var speed = 3
# The downward acceleration when in the air, in meters per second squared.
@export var fall_acceleration = 75
#@export var goal_position = 
# Emitted when the bulldog was hit by a chaser.
signal caught(body)
# Emitted when the bulldog is safe.
signal reached_safe_zone(body)
# Emitted when the bulldog is no longer active in this round.
signal inactive(body)

# Declare the variable to hold the player reference
var player
var state 

var parent = get_parent()

var runners_array = []
var chasers_array = []

var default_colour = Color.BLUE
var chaser_colour = Color.RED
var safe_colour = Color.GREEN


enum {
	RUN,
	CHASE,
	SAFE,
}

func _ready():
	
	# Function to perform setup tasks
	# Assume the player is named "Player" in the scene
	
	var parent = get_parent()
	print("parent of bulldog script", parent)
	if parent and parent.has_method("get_runners") and parent.has_method("get_chasers"):
		runners_array = parent.get_runners()
		chasers_array = parent.get_chasers()
		print(runners_array, chasers_array)  # Debugging: See the player list
	else:
		print("there was no parent found or runners/chasers array found")
	player = get_parent().get_node("Player")
	
	var safe_zone = get_parent().get_node("SafeZone")
	if safe_zone:
		safe_zone.body_entered.connect(_on_safe_zone_entered)
	
	# Ensure the player node exists
	if not player:
		print("Player node not found!")
		return
		
	if state == null:
		state = RUN
		print("State null, setting to: ", state)
	
	change_colour()

# for testing purposes - set destination for agent in nav area
func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("ui_accept"):
				change_colour()
				
func change_colour():
	var new_material = StandardMaterial3D.new()
	if state == CHASE:
		new_material.albedo_color = chaser_colour
	if state == RUN:
		new_material.albedo_color = default_colour
	if state == SAFE:
		new_material.albedo_color = safe_colour
	if not state:
		print("no state found")
	$MeshInstance3D.material_override = new_material

func nearest_point_on_line(P: Vector3) -> Vector3:
	"""
	Finds the nearest point on the infinite line defined by A and B from point P.

	:param A: Vector2 - First point on the line
	:param B: Vector2 - Second point on the line
	:param P: Vector2 - The external point e.g. the runners current pos
	:return: Vector2 - The nearest point on the line
	"""
	var A = Vector3(15,0.5,-23)
	var B = Vector3(-15,0.5,-23)
	var AB = B - A  # Direction vector of the line
	var AP = P - A  # Vector from A to P
	var t = AP.dot(AB) / AB.length_squared()  # Projection scalar
	return A + AB * t  # Nearest point on the line i.e destination

func _physics_process(_delta):
	if global_position.y < -10:
		on_fell_out_of_bounds()
	# Use state machine to CHASE or to RUN
	match state:
		CHASE:
			chase()
		RUN:
			run()
		SAFE:
			pass
			
""" Function to identify nearest runner object for chaser to chase """
func find_nearest_runner():
	# Ensure the runners_array isn't empty
	#print(runners_array, player)
	var parent = get_parent()
	var runners_array = parent.get_runners()
	if runners_array.is_empty():
		print("No runners available!")
	# default min_distance and nearest_runner to runner[0]
	var min_distance = INF
	var nearest_runner = null
	# check if any are nearer and update min_distance, nearest_runner and return nearest_runner
	for runner in runners_array:
		var distance = global_position.distance_to(runner.global_position)
		if distance < min_distance:
			min_distance = distance
			nearest_runner = runner
	return nearest_runner
# Get the vector to the player and chase (will change to become nearest runner put in a function)
func chase():
	# Get the vector to  nearest runner)
	var nearest_runner = find_nearest_runner() 
	var direction_to_nearest_runner = (nearest_runner.global_position - global_position)
	#print(direction_to_runner)
	# Update the velocity
	
	velocity = direction_to_nearest_runner.normalized() * speed
	if not is_on_floor():
		velocity.y = velocity.y - (fall_acceleration)
	move_and_slide()
			
# Get to the other side! TODO: while avoiding enemies
func get_flee_vector() -> Vector3:
	var flee_vector = Vector3.ZERO
	var nearest_chaser = get_nearest_chaser()
	
	if nearest_chaser:
		flee_vector = (global_transform.origin - nearest_chaser.global_transform.origin).normalized()

	return flee_vector
	
func get_nearest_chaser() -> Node3D:
	var nearest_chaser = null
	var min_distance = flee_radius
	var parent = get_parent()
	var chasers_array = parent.get_chasers()
	for chaser in chasers_array:
		var distance = global_transform.origin.distance_to(chaser.global_transform.origin)
		if distance < min_distance:
			min_distance = distance
			nearest_chaser = chaser
	return nearest_chaser

func run():
	var destination = nearest_point_on_line(global_position)
	var flee_vector = get_flee_vector()
	navigation_agent_3d.set_target_position(destination)
	destination = navigation_agent_3d.get_next_path_position()
	var blended_direction = (destination - global_transform.origin).normalized() * (1.0 - flee_weight) + flee_vector * flee_weight
	blended_direction = blended_direction.normalized()  # Normalize to prevent speed issues
	
	# Update the path
	velocity = blended_direction * speed
	if not is_on_floor():
		velocity.y = velocity.y - (fall_acceleration)
	move_and_slide()

func set_state(given_state):
	# switch state var to given state var
	state = given_state
	print("State set to: ", state)

""" Function to declare object is caught emit signal, change state and colour """
func is_caught():
	caught.emit(self)
	print(self.name, " was caught!")
	set_state(CHASE)
	change_colour()
	inactive.emit(self)

""" Function to detect when caught """
func _on_chaser_detector_body_entered(body: CharacterBody3D) -> void:
	if body.state == CHASE and self.state == RUN:
		self.is_caught()

""" Function to declare object has fallen out-of-bounds """
func on_fell_out_of_bounds() -> void:
		print(self,"has fallen out of bounds")
		global_position = Vector3(0,5,-22)
		self.is_caught()
		
	
func _on_safe_zone_entered(body: CharacterBody3D):
	if body == self and state == RUN:
		set_state(SAFE)
		reached_safe_zone.emit(self)  # Signal that this runner is safe
		change_colour()
		velocity = Vector3.ZERO
#		leave_from_runners_array()
		print(name, " has reached safety! ")
		inactive.emit(self)

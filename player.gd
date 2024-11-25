extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $PlayerNavigationAgent3D
@onready var platform_navigation_region: NavigationRegion3D = $"/root/Node3D/PlatformNavigationRegion3D"  # Assuming it’s a sibling node

var speed: float = 7.0
var target_position: Vector3 = Vector3.ZERO
var move_direction: Vector3 = Vector3.ZERO

# Define the manual bounds of the navigation region
var platform_bounds_min: Vector3 = Vector3(-10, 0, -10)  # Replace with actual bounds
var platform_bounds_max: Vector3 = Vector3(10, 10, 10)   # Replace with actual bounds

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Update movement direction based on WASD input.
	handle_wasd_movement(delta)
	
	# Check if the navigation is finished, if not move to the target point
	if not navigation_agent.is_navigation_finished():
		move_to_point(delta)
	else:
		# If we have a navigation target, move towards it using WASD input
		apply_input_movement(delta)
	
	# Apply platform navigation constraints, if necessary
	handle_platform_navigation()

# Move the character towards the next navigation point.
func move_to_point(delta: float) -> void:
	var target_pos: Vector3 = navigation_agent.get_next_path_position()
	var direction: Vector3 = global_position.direction_to(target_pos)
	
	# Smooth movement towards the target (using lerp for velocity)
	velocity = velocity.lerp(direction * speed, 0.1)
	
	# Rotate the character to face the target position
	face_direction(target_pos)
	
	# Apply movement using move_and_slide
	move_and_slide()

# Handle WASD input movement.
func handle_wasd_movement(delta: float) -> void:
	move_direction = Vector3.ZERO
	
	# Get input for WASD keys
	if Input.is_action_pressed("MoveForward"):  # W key
		move_direction.z -= 1
	if Input.is_action_pressed("MoveBackward"):  # S key
		move_direction.z += 1
	if Input.is_action_pressed("MoveLeft"):  # A key
		move_direction.x += 1  # Right movement should go in positive X direction
	if Input.is_action_pressed("MoveRight"):  # D key
		move_direction.x -= 1  # Left movement should go in negative X direction
	
	# Normalize the movement direction to avoid faster diagonal movement
	if move_direction != Vector3.ZERO:
		move_direction = move_direction.normalized()

# Apply movement using WASD input
func apply_input_movement(delta: float) -> void:
	velocity = move_direction * speed
	
	# Rotate the character to face the direction of movement
	if move_direction.length() > 0:
		face_direction(global_position + move_direction * 2)  # Rotate toward movement direction

	# Apply the movement with move_and_slide
	move_and_slide()

# Rotate the character to face a specific direction smoothly
func face_direction(target_pos: Vector3) -> void:
	# Ensure that the target position is different from the current position
	if global_position != target_pos:
		# Calculate direction vector (ignoring vertical axis)
		var direction = (target_pos - global_position).normalized()
		direction.y = 0  # Ignore the Y axis for rotation
		
		# Calculate the angle between the forward vector and the direction
		var target_angle = direction.angle_to(Vector3.FORWARD)  # Angle between direction and forward axis
		
		# Rotate based on the angle calculated (adjust for facing right)
		if direction.x < 0:
			target_angle = -target_angle  # Flip angle if moving left (negative X)

		# Smoothly rotate towards the target angle using lerp_angle
		rotation.y = lerp_angle(rotation.y, -target_angle, 0.1)  # 0.1 is the rotation speed

# Handle input events for setting the navigation target.
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("LeftMouse"):
		set_navigation_target()

# Sets the target position for the navigation agent based on a raycast.
func set_navigation_target() -> void:
	var camera: Camera3D = get_tree().get_nodes_in_group("Camera")[0] as Camera3D
	var mouse_pos: Vector2 = $"../UICanvasLayer/HBoxContainer/LeftCamera/SubViewport".get_mouse_position()
	var ray_length: float = 100.0
	
	# Calculate ray from camera through the mouse position
	var ray_origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var ray_target: Vector3 = ray_origin + camera.project_ray_normal(mouse_pos) * ray_length
	
	var space_state: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var ray_query = PhysicsRayQueryParameters3D.new()
	ray_query.from = ray_origin
	ray_query.to = ray_target
	ray_query.collide_with_areas = true
	
	# Perform the raycast to find the target point
	var result = space_state.intersect_ray(ray_query)
	
	if result:
		# If we hit something, set the navigation target to the intersection point
		target_position = result.position
	else:
		# If no hit, set the navigation target to the current position
		target_position = global_position
	
	# Clamp the navigation target within the platform bounds
	target_position = clamp_vector3(target_position, platform_bounds_min, platform_bounds_max)
	
	# Update the navigation agent with the new target position
	navigation_agent.target_position = target_position

# Handle platform-based navigation constraints
func handle_platform_navigation() -> void:
	# Clamp the player's position within the manually defined bounds
	global_position = clamp_vector3(global_position, platform_bounds_min, platform_bounds_max)

# Clamp a Vector3 within specified bounds
func clamp_vector3(value: Vector3, min_bounds: Vector3, max_bounds: Vector3) -> Vector3:
	return Vector3(
		clamp(value.x, min_bounds.x, max_bounds.x),
		clamp(value.y, min_bounds.y, max_bounds.y),
		clamp(value.z, min_bounds.z, max_bounds.z)
	)

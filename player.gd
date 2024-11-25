extends CharacterBody3D

@onready var navigation_agent: NavigationAgent3D = $PlayerNavigationAgent3D
@onready var platform_navigation_region: Node3D = $PlatformNavigationRegion3D  # Assuming it’s a sibling node

var speed: float = 7.0
var target_position: Vector3 = Vector3.ZERO
var move_direction: Vector3 = Vector3.ZERO

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
	if Input.is_action_pressed("MoveRight"):  # D key
		move_direction.x -= 1
	if Input.is_action_pressed("MoveLeft"):  # A key
		move_direction.x += 1
	
	# Normalize the movement direction to avoid faster diagonal movement
	if move_direction != Vector3.ZERO:
		move_direction = move_direction.normalized()

# Apply movement using WASD input
func apply_input_movement(delta: float) -> void:
	velocity = move_direction * speed
	
	# Rotate the character to face the direction of movement
	if move_direction.length() > 0:
		face_direction(global_position + move_direction)

	# Apply the movement with move_and_slide
	move_and_slide()

# Rotate the character to face a specific direction.
func face_direction(target_pos: Vector3) -> void:
	# Only rotate on the XZ plane (y is kept constant)
	look_at(Vector3(target_pos.x, global_position.y, target_pos.z), Vector3.UP)

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
	
	# Update the navigation agent with the new target position
	navigation_agent.target_position = target_position

# Handle platform-based navigation constraints
func handle_platform_navigation() -> void:
	# Assuming you want to check if the player is within the boundaries of the platform navigation region
	# You can use the platform's navigation area to query valid positions or adjust as needed
	
	# Example: Ensure the player remains within the valid bounds of the platform navigation region
	if platform_navigation_region:
		var navigation_area = platform_navigation_region.get_child(0)  # Assuming it has a NavigationMesh or similar child
		if navigation_area and navigation_area is NavigationRegion3D:
			# Here, we can query the valid position within the navigation area or constrain the movement
			var valid_position = navigation_area.get_closest_navigation_position(global_position)
			if valid_position != global_position:
				global_position = valid_position  # Correct the player position if needed

extends CharacterBody3D

class_name Player

# physics constants
const GRAVITY = 1 # self explanatory
const FRICTION = 1.3 # applied when on ground or not pressing anything in the air

# player action speeds
const MOVE_SPEED = 13 # horizontal movement speed
const AIR_MOVE_SPEED = 5
const JUMP_VELOCITY = 25 # vertical force when jumping
const JUMP_FORWARDS_VELOCITY = 8 # a little boost we get when jumping, actually pushes player in input direction
const WALL_SPEED_BONUS = 3 # extra speed from wall running
const WALL_JUMP_HORIZONTAL_FORCE = 20 # force we propell off walls
const WALL_REPULSION_FORCE = 30 # force keeping you away from wall

# tolerance values
const DEADZONE = 0.1 # time we can still jump after leaving an object
const FRICTION_DEADZONE = 0.1 # only applies frictin after being on the ground for this time, allows bunny hopping
const INPUT_BUFFER_TIME = 0.1 # just used to let you press jump before you hit the ground
const WALL_FORCETIME = 0.1 # time you're forced away from a wall

var airtime = 0
var landtime = 0
var sens = 0.2
var mouse_captured = false
var v = Vector3.ZERO
var last_wall_collision = Vector3.ZERO
var last_input = INPUT_BUFFER_TIME
var last_wall_jump = WALL_FORCETIME

@onready var mesh = $"MeshInstance3D"
@onready var collision = $"CollisionShape3D"

func _ready():
	pass

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && mouse_captured:
		rotate_y(deg_to_rad(-event.relative.x*sens))
		$Camera3D.rotate_x(clamp(deg_to_rad(-event.relative.y*sens),-PI/2,PI/2))

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("Capture_Mouse"):
		if mouse_captured:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			mouse_captured = false
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			mouse_captured = true
	default_movement(delta)
	
func default_movement(delta):
	var frame_velocity = Vector3.ZERO
	
	# calc horizontal forces from input
	var input_dir := Input.get_vector("Move_Left", "Move_Right", "Move_Forward", "Move_Back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# most basic movement
	if !is_on_floor() && is_on_wall():
		frame_velocity.x = direction.x * (MOVE_SPEED + WALL_SPEED_BONUS)
		frame_velocity.z = direction.z * (MOVE_SPEED + WALL_SPEED_BONUS)
	elif !is_on_floor():
		frame_velocity.x = direction.x * AIR_MOVE_SPEED
		frame_velocity.z = direction.z * AIR_MOVE_SPEED
	else:
		frame_velocity.x = direction.x * MOVE_SPEED
		frame_velocity.z = direction.z * MOVE_SPEED
	
	# calc vertical forces
	if not is_on_floor():
		frame_velocity.y = -GRAVITY
	
	# wall gravity is inversely related to speed
	if is_on_wall():
		var div = max(Vector2(v.x,v.z).length(),1)
		if v.y <= 0:
			if direction.length() > 0:
				v.y = -clamp(GRAVITY/div,0,GRAVITY)
			else:
				frame_velocity.y = -clamp(GRAVITY/div,0,GRAVITY)
		else:
			frame_velocity.y = -GRAVITY
	
	# if we're on the floor, our y velocity is 0
	if is_on_floor() && v.y < 0:
		v.y = 0
		
	# give a small deadzone after elaving either where you can still jump
	if is_on_floor() || is_on_wall():
		airtime = 0
		landtime += delta
	else:
		airtime += delta
		landtime = 0
		
	if is_on_wall() && !is_on_floor():
		if last_wall_collision != get_last_slide_collision().get_normal():
			last_wall_collision = get_last_slide_collision().get_normal()
			last_wall_jump = WALL_FORCETIME # fixes buggy interaction if you jump between walls too fast
		
	var jumped = Input.is_action_just_pressed("Jump")
	if (jumped || last_input < INPUT_BUFFER_TIME) && airtime < DEADZONE:
		# wall jump or normal jump
		if is_on_wall() && !is_on_floor():
			last_wall_jump = 0
			var jump_velocity = last_wall_collision*WALL_JUMP_HORIZONTAL_FORCE
			jump_velocity.y = JUMP_VELOCITY
			frame_velocity = jump_velocity
		else:
			frame_velocity.y = JUMP_VELOCITY
			
		frame_velocity += direction * JUMP_FORWARDS_VELOCITY
		last_input = INPUT_BUFFER_TIME+1 # no exploiting
	elif jumped: # input buffer
		last_input = -delta
	last_input += delta
	
	# wall force is only applied if moving back towards wall
	if last_wall_jump < WALL_FORCETIME && !is_on_floor():
		var force =  last_wall_collision*WALL_REPULSION_FORCE
		if (v + force).length() < v.length():
			frame_velocity += force
	last_wall_jump += delta
		
	# we only add our speed if we are below it, and we don't cap our speed
	if sign(frame_velocity.x) == sign(v.x):
		v.x = sign(v.x)*max(abs(frame_velocity.x), abs(v.x))
	else:
		v.x += frame_velocity.x
	if sign(frame_velocity.z) == sign(v.z):
		v.z = sign(v.z)*max(abs(frame_velocity.z), abs(v.z))
	else:
		v.z += frame_velocity.z
		
	# update velocity from last frame
	v.y += frame_velocity.y
	
	# apply velocity
	velocity = v
	move_and_slide()
	
	if (landtime > FRICTION_DEADZONE || airtime > DEADZONE) && (is_on_floor() || direction.length() == 0):
		v /= Vector3(FRICTION,1,FRICTION)

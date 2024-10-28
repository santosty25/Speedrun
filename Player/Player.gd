extends CharacterBody3D

class_name Player

# physics constants
const GRAVITY = 1 # self explanatory
const FRICTION = 1.3 # applied when on ground or not pressing anything in the air
const SLIDE_FRICTION = 1.01 # friction while sliding

# player action speeds
const MOVE_SPEED = 13 # horizontal movement speed on ground and wall
const AIR_MOVE_SPEED = 5 # horizontal movement speed in air
const JUMP_VELOCITY = 25 # vertical force when jumping
const JUMP_FORWARDS_VELOCITY = 8 # forward movement boost on jump 
const WALL_SPEED_BONUS = 3 # extra speed from wall running
const WALL_JUMP_HORIZONTAL_FORCE = 20 # force player propells off walls on initial jump
const WALL_REPULSION_FORCE = 50 # force keeping player away from wall after wall jumping
const AIR_JUMP_COUNT = 1 # number of double jumps you get, 0 means no double jumping
const DASH_COOLDOWN = 0.5 # time it takes to regenerate one dash
const DASH_COUNT = 1 # number of dashes player can have stocked at once
const DASH_SPEED = 60 # speed player moves while dashing
const DASH_TIME = 0.1 # time dash lasts
const SLIDE_BOOST = 30 # initial speed given for slide
const MAX_SHAKE = 1
const MAX_SHAKE_SPEED = 10
const MIN_SHAKE_SPEED = 0
const SHAKE_RATE = 0.1

# tolerance values
const DEADZONE = 0.1 # time we can still jump after leaving an object
const FRICTION_DEADZONE = 0.1 # only applies frictin after being on the ground for this time, allows bunny hopping
const INPUT_BUFFER_TIME = 0.1 # just used to let you press jump before you hit the ground
const WALL_FORCETIME = 0.1 # time you're forced away from a wall
# how dashes should be reset
# COOLDOWN - a dash charge regenerates every time the cooldown timer runs out
# HOLLOW_KNIGHT - dashes are treated like a resource which regens instantly when you land. Enforces dash cooldown only when dashing on ground or walls
enum DASH_TYPE {COOLDOWN,HOLLOW_KNIGHT}
const DASH = DASH_TYPE.HOLLOW_KNIGHT
# whether the dash direction should be based on input direction or direction player is facing
enum DASH_MOVE_TYPE {INPUT,FACING}
const DASH_DIR_TYPE = DASH_MOVE_TYPE.FACING
const DASH_PERSIST_TIME = 0.1 # time slide friction is still applied after ending a slide

var airtime := 0.0
var landtime := 0.0
var sens := 0.2
var mouse_captured := false
var v := Vector3.ZERO
var last_wall_collision := Vector3.ZERO
var last_input := INPUT_BUFFER_TIME
var last_wall_jump := WALL_FORCETIME
var air_jumps_left := 1
var dash_timer := 0.0
var dashes_left := DASH_COUNT
var dash_counters := []
var dash_direction := Vector3.ZERO
var is_sliding := false
var slide_persist_timer = 0
var slide_camera_corrected = true
var shake_counter = 0


var win = false

@onready var mesh = $"MeshInstance3D"
@onready var collision = $"CollisionShape3D"
@onready var camera = $"Camera3D"

func _ready():
	if DASH == DASH_TYPE.HOLLOW_KNIGHT:
		dash_counters = [0]

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion && mouse_captured:
		rotate_y(deg_to_rad(-event.relative.x*sens))
		camera.rotate_x(deg_to_rad(-event.relative.y*sens))
		camera.rotation.x = clamp(camera.rotation.x,-PI/2,PI/2)

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
		air_jumps_left = AIR_JUMP_COUNT
		if DASH == DASH_TYPE.HOLLOW_KNIGHT:
			dashes_left = DASH_COUNT
	else:
		airtime += delta
		landtime = 0
		
	if is_on_wall() && !is_on_floor():
		if last_wall_collision != get_last_slide_collision().get_normal():
			last_wall_collision = get_last_slide_collision().get_normal()
			last_wall_jump = WALL_FORCETIME # fixes buggy interaction if you jump between walls too fast
		
	var jumped = Input.is_action_just_pressed("Jump")
	if (jumped || last_input < INPUT_BUFFER_TIME) && (airtime < DEADZONE || air_jumps_left > 0):
		# wall jump or normal jump
		if is_on_wall() && !is_on_floor():
			last_wall_jump = 0
			var jump_velocity = last_wall_collision*WALL_JUMP_HORIZONTAL_FORCE
			jump_velocity.y = JUMP_VELOCITY
			frame_velocity = jump_velocity
		else:
			v.y = JUMP_VELOCITY
			if !is_on_floor():
				air_jumps_left -= 1
			
		frame_velocity += direction * JUMP_FORWARDS_VELOCITY
		last_input = INPUT_BUFFER_TIME+1 # no exploiting
	elif jumped: # input buffer
		last_input = -delta
	last_input += delta
		
	# handle sliding
	if Input.is_action_pressed("Slide") && is_on_floor():
		is_sliding = true
		frame_velocity = Vector3.ZERO
		# rotate player on first frame
		if slide_camera_corrected:
			frame_velocity = direction*SLIDE_BOOST
			rotation.x = PI/2
			camera.rotation.x -= PI/2
			slide_camera_corrected = false
			position.y -= 1
	else:
		is_sliding = false
		if !slide_camera_corrected:
			camera.rotation.x += PI/2
			rotation.x = 0
			slide_camera_corrected = true
		
	# increment dash cooldowns
	var i = 0
	while i < len(dash_counters):
		if dash_counters[i] > 0: # decrement
			dash_counters[i] -= delta
		elif DASH == DASH_TYPE.COOLDOWN: # if necessary, remove
			dash_counters.remove_at(i)
			dashes_left += 1
			i -= 1
		i += 1
	if DASH == DASH_TYPE.HOLLOW_KNIGHT && !is_on_floor() && !is_on_wall():
		dash_counters[0] = 0
		
	# handle dashing
	var dashed = false
	# can't dash while sliding, must release button
	if Input.is_action_just_pressed("Dash") && !is_sliding && dashes_left > 0:
		if DASH == DASH_TYPE.COOLDOWN:
			dashed = true
			dashes_left -= 1
			dash_counters.append(DASH_COOLDOWN)
		elif DASH == DASH_TYPE.HOLLOW_KNIGHT:
			if is_on_floor() || is_on_wall():
				# can only dash under these conditions if cooldown is out
				if dash_counters[0] <= 0:
					dash_counters[0] = DASH_COOLDOWN
					dashed = true
			else:
				# if in air, acts like normal
				if dashes_left > 0:
					dashed = true
					dashes_left -= 1
	
	# tell player to actually dash
	if dashed:
		dash_timer = DASH_TIME
		if DASH_DIR_TYPE == DASH_MOVE_TYPE.INPUT:
			if direction.length() != 0:
				dash_direction = direction
			else:
				dash_direction = (transform.basis * Vector3(0,0,-1)).normalized()
		elif DASH_DIR_TYPE == DASH_MOVE_TYPE.FACING:
			dash_direction = (transform.basis * Vector3(0,0,-1)).normalized()
			dash_direction = dash_direction.rotated(transform.basis * Vector3(1,0,0),camera.rotation.x)
	
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
		
	# if we're in a dash, overwrite movement
	if dash_timer > 0:
		v = dash_direction * DASH_SPEED
		frame_velocity = Vector3.ZERO
		dash_timer -= delta
		
	# update velocity from last frame
	v.y += frame_velocity.y
	
	# apply velocity
	velocity = v
	move_and_slide()
	
	if velocity.length() > MIN_SHAKE_SPEED:
		if shake_counter < SHAKE_RATE:
			shake_counter += delta
		else:
			shake_counter = 0
			var p = min(velocity.length()/MAX_SHAKE_SPEED,1)
			var offset = Vector2(randf(),randf()).normalized()*MAX_SHAKE*p
			camera.v_offset = p.x
			camera.h_offset = p.y
		
	
	#print(str(landtime)+" "+str(airtime)+" "+str(is_on_floor())+" "+str(direction.length()))
	if (landtime > FRICTION_DEADZONE || airtime > DEADZONE) && (is_on_floor() || direction.length() == 0):
		if is_sliding || slide_persist_timer > 0:
			v /= Vector3(SLIDE_FRICTION,1,SLIDE_FRICTION)
			slide_persist_timer -= delta
		else:
			v /= Vector3(FRICTION,1,FRICTION)


func _on_end_ground_body_entered(body):
	if body is CharacterBody3D:
		win = true

extends Node3D

var rotationSpeed = -60  
var player = null

var currRot := 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	currRot = rotationSpeed * delta
	rotate_y(deg_to_rad(currRot))

func _on_area_3d_body_entered(body):
	if body == $Player:
		player = body


func _on_area_3d_body_exited(body):
	if body == player:
		player = null

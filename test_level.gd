extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_pressed("Reset"):
		$Player.position = Vector3(0, 0, 0)
		$Player.rotation = Vector3(0, 0, 0)

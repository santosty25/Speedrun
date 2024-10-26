extends Node2D

var leaderboardShow = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass # Replace with function body.


func _on_leaderboard_pressed() -> void:
	$Control1.position = Vector2(2000, 0)
	leaderboardShow = true
	

func _on_controls_pressed() -> void:
	$ControlsPic.position = Vector2(592, 331)
	$Control1.position = Vector2(2000, 0)
	$Control2.position = Vector2(0, 0)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_button_pressed() -> void:
	$ControlsPic.position = Vector2(-477, 366)
	$Control1.position = Vector2(0, 0)
	$Control2.position = Vector2(2000, 0)
	leaderboardShow = false

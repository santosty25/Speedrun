extends Node2D

var game_scene = preload("res://Scenes/Test_Level.tscn").instantiate()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Test_Level.tscn")


func _on_controls_button_pressed() -> void:
	$ControlsPic.position = Vector2(592, 331)
	$Control1.position = Vector2(2000, 0)
	$Control2.position = Vector2(0, 0)

func _on_quit_button_pressed() -> void:
	get_tree().quit()


func _on_button_pressed() -> void:
	$ControlsPic.position = Vector2(-477, 366)
	$Control1.position = Vector2(0, 0)
	$Control2.position = Vector2(2000, 0)

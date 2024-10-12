extends Node3D

var time = 0.0
var sec = 0
var min = 0
var centi = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta * 100
	
	if !$Player.win:
		$Stopwatch.text = getTime()
	
	if Input.is_action_pressed("Reset"):
		$Player.position = Vector3(0, 0, 0)
		$Player.rotation = Vector3(0, 0, 0)
		time = 0
		$Player.win = false
		

#Turns total centiseconds into stopwatch time format
func getTime():	
	min = int(time) / 6000
	sec = (int(time) - (6000 * min)) / 100
	centi = int(time) - ((100 * sec) + (6000 * min))
	
	#Turns all three time increments into string and combines them into format
	var timerString1 = ""
	var timerString2 = ""
	var timerString3 = ""
	
	#Makes sure time increments always have two digits
	if (min <= 9):
		timerString1 = "0" + str(min)
	else:
		timerString1 = str(min)
	if (sec <= 9):
		timerString2 = "0" + str(sec)
	else:
		timerString2 = str(sec)
	if (centi <= 9):
		timerString3 = "0" + str(centi)
	else:
		timerString3 = str(centi)
		
	return timerString1 + ":" + timerString2 + "." + timerString3

extends Node3D

var time = 0.0
var sec = 0
var min = 0
var centi = 0
# new changes
var leaderboard = []
const leaderboard_path = "user://Leaderboard.json"
const recording_path = "user://Recording.json"

var recording = []
var bestTime = []
@onready var ghost = $Ghost
var recordingTimer = 0
const UPDATE_SPEED = 1.0/60

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#new change
	load_leaderboard()
	update_leaderboard_ui()
	$LeaderBoard.visible = false

# Add to leaderboard and save if a new best time is achieved
func update_leaderboard(time):
	leaderboard.append(time)
	leaderboard.sort() # Assuming lower times are better
	if leaderboard.size() > 5:
		leaderboard.pop_back() # Keep only top 5
	save_leaderboard()

func load_leaderboard():
	# Check if the file exists
	if FileAccess.file_exists(leaderboard_path):
		var file = FileAccess.open(leaderboard_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var text = file.get_as_text()  # Read the file content
			var parsed_data = json.parse(text)  # Parse the JSON data
			if parsed_data == OK:
				leaderboard = json.get_data()  # Retrieve the parsed data
				print("Leaderboard loaded successfully:", leaderboard)
			else:
				print("Error parsing JSON:", json.get_error_string(parsed_data))  # Print error string
				file.close()
		else:
			print("Error: Could not open file to load leaderboard.")
	else:
		print("Leaderboard file does not exist. Creating new file.")
		save_leaderboard()
		
	if FileAccess.file_exists(recording_path):
		var file = FileAccess.open(recording_path, FileAccess.READ)
		if file:
			var json = JSON.new()
			var text = file.get_as_text()  # Read the file content
			var parsed_data = json.parse(text)  # Parse the JSON data
			if parsed_data == OK:
				bestTime = json.get_data()  # Retrieve the parsed data
				print("Recording loaded successfully")
			else:
				print("Error parsing JSON:", json.get_error_string(parsed_data))  # Print error string
				file.close()
		else:
			print("Error: Could not open file to load recording.")
	else:
		print("Recording file does not exist. Creating new file.")
		save_recording()


func save_leaderboard():
	# Opens the file in write mode and saves the leaderboard as JSON
	var file = FileAccess.open(leaderboard_path, FileAccess.WRITE)
	if file:
		var json = JSON.new()
		file.store_string(json.stringify(leaderboard))  # Write actual leaderboard data to file
		print("Leaderboard saved:", leaderboard)
		file.close()
	else:
		print("Error: Could not open file to save leaderboard.")
		
func save_recording():
	# Opens the file in write mode and saves the leaderboard as JSON
	var file = FileAccess.open(recording_path, FileAccess.WRITE)
	if file:
		var json = JSON.new()
		file.store_string(json.stringify(recording))  # Write actual leaderboard data to file
		print("Recording saved")
		file.close()
	else:
		print("Error: Could not open file to save recording.")

# Update the UI with the leaderboard times
func update_leaderboard_ui():
	var allScores = "LEADERBOARD"
	for i in range(leaderboard.size()):
		var label = $LeaderBoard/HBoxContainer/VBoxContainer.get_node("Label" + str(i + 1))
		if label:
			label.text = str(i + 1) + ": " + leaderboard[i]  # Display rank and time
			allScores = allScores+"\n"+label.text
	for i in range(5-leaderboard.size()):
		allScores = allScores+"\n"+str(leaderboard.size()+i+1)+": ___:___.___"
	$Label3D.text = allScores
# Called when the player wins
# Called when the player wins
func on_player_win():
	var final_time = getTime()  # Get formatted stopwatch time
	if $Player.verify_run():
		if $Player.win:
			print("Players winning time: ", final_time)
			if len(leaderboard) == 0 || final_time < leaderboard[0]:
				save_recording()
				load_leaderboard()
			update_leaderboard(final_time)  # Add formatted time to leaderboard
			update_leaderboard_ui()  # Update the UI to show the new leaderboard
			$Stopwatch.text = final_time  # Display final time on the stopwatch
			$Player.win = true

			# Reset player position and state
			reset_player()
			reset_ghost()
	else:
		reset_player()
		
	$LastScore.text = "PREVIOUS SCORE\n"+str(final_time)

# Function to reset player position and state
func reset_player():
	$Player.position = Vector3(0, 0, 0)  # Set to starting position
	$Player.rotation = Vector3(0, 0, 0)  # Reset rotation
	time = 0  # Reset timer
	$Stopwatch.text = getTime()  # Update stopwatch display
	$Player.win = false  # Reset win state
	recording.clear()
	recordingTimer = 0
	$Player.reset_run()
	reset_ghost()
	
func reset_ghost():
	ghost.visible = true  # Make ghost visible again
	recordingTimer = 0  # Reset the ghost's recording timer
	if bestTime.size() > 0:
		ghost.position = Vector3(0, 0, 0)  # Start ghost at the initial position
	else:
		ghost.visible = false  # Hide ghost if there's no recorded best time

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if !$Player/Music.playing:
		$Player/Music.play()
	time += delta * 100
	
	if $Player.velocity.y < -150:
		reset_player();
	
	if !$Player.win && !$Player.pause:
		$Stopwatch.text = getTime()
	else:
		on_player_win()
	
	if Input.is_action_pressed("Reset"):
		reset_player()
	if Input.is_action_pressed("Reset") && !$Player.pause:
		$Player.position = Vector3(0, 0, 0)
		$Player.rotation = Vector3(0, 0, 0)
		time = 0
		$Player.win = false
	
	$PauseMenu.visible = $Player.pause
	if $PauseMenu.visible:
		$LeaderBoard.visible = $PauseMenu.leaderboardShow
	else:
		$LeaderBoard.visible = false
	
	$PauseMenu/Control1/NuxModeText.visible = !$Player.nuxMode

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
	
#func _physics_process(delta: float) -> void:
	# only record if below record
#	if len(leaderboard) == 0 || getTime() < leaderboard[0]:
#		recording.append($Player.position)
#		
#	recordingTimer += delta
#	var recFrame = floori(recordingTimer / UPDATE_SPEED)
#	
#	if recFrame < len(bestTime):
#		var axes = bestTime[recFrame].replace("(","").replace(")","").replace(" ","").split(",")
#		var ghostPos = Vector3(int(axes[0]),int(axes[1]),int(axes[2]))
#		ghost.position = ghostPos
#	elif len(bestTime) > 0:
#		ghost.position = bestTime.back()
#	
#	else:
#		pass

func _physics_process(delta: float) -> void:
	# Only record if below record
	if len(leaderboard) == 0 or getTime() < leaderboard[0]:
		recording.append($Player.position)
		
	recordingTimer += delta
	var recFrame = floori(recordingTimer / UPDATE_SPEED)
	
	if recFrame < bestTime.size():
		# Parse the string to a Vector3 if it's in the string format "(x, y, z)"
		var axes = bestTime[recFrame].replace("(", "").replace(")", "").replace(" ", "").split(",")
		if axes.size() == 3:
			var ghostPos = Vector3(axes[0].to_float(), axes[1].to_float(), axes[2].to_float())
			ghost.position = ghostPos
	else:
		# Hide the ghost once it finishes the race
		ghost.visible = false



func _on_button_pressed() -> void:
	$PauseMenu._on_button_pressed()

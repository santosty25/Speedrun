extends Node3D

var time = 0.0
var sec = 0
var min = 0
var centi = 0
# new changes
var leaderboard = []
const leaderboard_path = "C:\\Users\\kawik\\OneDrive\\Desktop\\UniversityOfPortland\\Fall2024\\CS447\\leaderboard.json"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass
	#new change
	load_leaderboard()
	update_leaderboard_ui()

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

# Update the UI with the leaderboard times
func update_leaderboard_ui():
	for i in range(leaderboard.size()):
		var label = $LeaderBoard/VBoxContainer.get_node("Label" + str(i + 1))
		if label:
			label.text = str(i + 1) + ": " + leaderboard[i]  # Display rank and time
			
# Called when the player wins
# Called when the player wins
func on_player_win():
	if $Player.win:
		var final_time = getTime()  # Get formatted stopwatch time
		print("Players winning time: ", final_time)
		update_leaderboard(final_time)  # Add formatted time to leaderboard
		update_leaderboard_ui()  # Update the UI to show the new leaderboard
		$Stopwatch.text = final_time  # Display final time on the stopwatch
		$Player.win = true

		# Reset player position and state
		reset_player()
	else:
		print("Player has already won")

# Function to reset player position and state
func reset_player():
	$Player.position = Vector3(0, 0, 0)  # Set to starting position
	$Player.rotation = Vector3(0, 0, 0)  # Reset rotation
	time = 0  # Reset timer
	$Stopwatch.text = getTime()  # Update stopwatch display
	$Player.win = false  # Reset win state
	
# Example usage when player wins
#func on_player_win():
#	if !$Player.win:
#		update_leaderboard(time)
#		$Stopwatch.text = getTime()
#		$Player.win = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta * 100
	
	if !$Player.win:
		$Stopwatch.text = getTime()
	else:
		on_player_win()
	
	if Input.is_action_pressed("Reset"):
		reset_player()
		

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

extends Node

@export var background_music: AudioStreamPlayer
var target_volume: float = 0  # Target volume (in decibels)
var volume_change_per_second: float

func _ready()-> void:

	# Start playing the background music at a very low volume
	background_music.volume_db = -80  # Set to a very low volume
	background_music.play()

	# Call the fade-in function
	fade_in_music()

func fade_in_music() -> void:
	# Target volume to achieve (0 dB is maximum volume)
	var fade_duration: float = 3  # Duration for fading in (in seconds)

	# Calculate the change in volume per second to achieve the fade effect
	volume_change_per_second = -background_music.volume_db / fade_duration

# Function to gradually increase volume every frame
func _process(delta: float) -> void:
	if background_music.volume_db < target_volume:
		background_music.volume_db += volume_change_per_second * delta
	else:
		# Ensure volume doesn't exceed the target volume
		background_music.volume_db = target_volume
		# Disable this _process function when fade-in is complete
		set_process(false)

	# Start the fading effect by enabling the _process function
	set_process(true)

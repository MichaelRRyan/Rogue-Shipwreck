extends Control

func _ready():
	$PlayButton.grab_focus()
	$MusicPlayer.play()

func _on_PlayButton_pressed():
	if get_tree().change_scene("res://Scenes/Intro.tscn") != OK:
		print ("An unexpected error occured when trying to switch to the Intro scene")

func _on_ExitButton_pressed():
	get_tree().quit()

